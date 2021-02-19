#!/usr/bin/env perl
use strict;
use warnings;
use Log::Log4perl qw(:easy);
use Config::Simple;
use Getopt::Long;
use File::Slurp;
use File::Temp;
use Pod::Usage;
use Try::Tiny;
use Net::Domain;
use DBI;
use autodie;
use Parallel::ForkManager;

use constant SQL_RUNTIME => "INSERT INTO runtime(label,elapsed_time,user_time,system_time,pcpu,mrss,arss,avg_mem_usage,exit_status,hostname,setup_exit_status,teardown_exit_status) VALUES(?,?,?,?,?,?,?,?,?,?,?,?)";
use constant SQL_SYS_INFO => "INSERT INTO system_info(hostname, pmem_usage, pcpu_usage) VALUES(?,?,?)";
use constant INVALID_SYSINFO => -1.0;

my $dbname = "data/timings.db";
my $cmds = "etc/cmds.tab";
my $cfg = "etc/timing.ini";
my $num_repeats = 1;
my $parallel = 0;  # run jobs in parallel
my $dry_run = 0;
my $verbose = 0;
my $skip_failures = 0;
my $rm_core_files = 0;
my $sampling_interval = 1;
my $logfile = "";
my $help_requested = 0;
GetOptions("db=s"           => \$dbname,
           "cmds=s"         => \$cmds,
           "cfg=s"          => \$cfg,
           "repeats=i"      => \$num_repeats,
           "parallel"       => \$parallel,
           "skip_failures"  => \$skip_failures,
           "rm_core_files"  => \$rm_core_files,
           "verbose|v+"     => \$verbose,
           "dry_run"        => \$dry_run,
           "logfile=s"      => \$logfile,
           "help|?"         => \$help_requested) || pod2usage(2);
pod2usage(-verbose=>2) if ($help_requested);
pod2usage("Missing command file") unless (-s $cmds);
pod2usage("Missing database") unless (-s $dbname);
pod2usage("Invalid number of repeats") unless ($num_repeats > 0);
$verbose = 5 if ($dry_run and $verbose == 0);
$num_repeats = 1 if $parallel;

try {
    init_logging($logfile, $verbose);
    main();
} catch {
    LOGDIE("Caught exception: $_");
};

# Crude way to get the number of processors in linux
sub get_num_procs
{
    open (my $handle, "<", "/proc/cpuinfo");
    my $retval = scalar (map /^processor/, <$handle>);
    close $handle;
    return $retval;
}

sub main
{
    $|++;

    my @lines = grep { !/^#|^$/ } read_file($cmds);
    my $num_parallel_jobs = scalar(@lines);
    my $num_procs = &get_num_procs;
    if ($num_parallel_jobs > $num_procs) {
        LOGDIE("The number of commands ($num_parallel_jobs) exceeds the number of available processors ($num_procs)");
    }
    my $pm = $parallel
        ? Parallel::ForkManager->new($num_parallel_jobs)
        : undef;

    # From man page
    # %e: elapsed time in seconds
    # %U: CPU-seconds in user space
    # %S: CPU-seconds in kernel
    # %P: Percentage CPU, computed as (%U + %S) / %E.
    # %M: Maximum resident set size of the process during its lifetime, in Kbytes.
    # %t: Average resident set size of the process, in Kbytes.
    # %K: Average total (data+stack+text) memory use of the process, in Kbytes.
    $ENV{TIME} = "%e\t%U\t%S\t%P\t%M\t%t\t%K";

    my $dbh = connect_to_sqlite($dbname);
    my $sth_runtime = $dbh->prepare(SQL_RUNTIME);
    my $sth_sysinfo = $dbh->prepare(SQL_SYS_INFO);
    my $host = Net::Domain::hostfqdn();
    my %config;
    Config::Simple->import_from($cfg, \%config) if -f $cfg;
    DEBUG("Read config file $cfg") if -f $cfg;

    if (defined $pm) {
        $pm->run_on_finish( sub {
            my ($pid, $exit_code, $ident) = @_;
            DEBUG("Child PID $pid ($ident) finished with exit code $exit_code");
        });
        $pm->run_on_wait( sub {
            my $pmem = &collect_mem_usage();
            my $pcpu = &collect_cpu_usage();
            return if ($pmem == INVALID_SYSINFO or $pcpu == INVALID_SYSINFO);
            TRACE("system_info: mem: $pmem%, CPU=$pcpu%");
            &save2db($sth_sysinfo, $host, ($pmem, $pcpu)) unless $dry_run;
        }, $sampling_interval);
    }

    DATA_LOOP:
    foreach (@lines) {
        chomp;
        my $pid = 0;
        if (defined $pm) {
            $pid = $pm->start($_) and next DATA_LOOP;
        }
        my @F = split(/\t/);
        LOGDIE("Invalid input: tab separated label and command expected") if (@F != 2);
        my $label = $F[0];
        my $cmd2time = $F[1];
    # HACK FOR SPARK AND OUTPUT IN HDFS
    my $output;
    if ($cmd2time =~ /spark-submit.*\.txt\s+(.*)\s+DUMMY_RID$/) {
        $output = $1;
    }
    ###################################### 
        for (my $run_number = 0; $run_number < $num_repeats; $run_number++) {
            my ($setup_exit_code, $exit_code, $teardown_exit_code) = (0)x3;
            my $label4run = $label . "-" . ($run_number+1);
            $label4run = $label if ($num_repeats == 1);
        # HACK FOR SPARK AND OUTPUT IN HDFS
        if (defined $output and $num_repeats != 1) {
            $cmd2time = $F[1];
            my $output4run = $output . "-" . ($run_number+1);
            $cmd2time =~ s/$output/$output4run/;
        }
        #####################################
            if (exists $config{"$label.setup"}) {
                try { run($config{"$label.setup"}); } 
                catch { WARN("$label.setup command FAILED"); }
                finally { $setup_exit_code = $IPC::System::Simple::EXITVAL; };
            } elsif (exists $config{"all.setup"}) {
                try { run($config{"all.setup"}); } 
                catch { WARN("all.setup command FAILED"); }
                finally { $setup_exit_code = $IPC::System::Simple::EXITVAL; };
            }
            my $tmp_fh = File::Temp->new();
            my $cmd = "/usr/bin/time -o $tmp_fh $cmd2time";
            if ($skip_failures) {
                try { run($cmd); } catch { $run_number = $num_repeats; }
                finally { $exit_code = $IPC::System::Simple::EXITVAL; };
            } else  {
                run($cmd); 
                $exit_code = $IPC::System::Simple::EXITVAL;
            }
            chomp(my @timings = read_file($tmp_fh->filename));
            my $line_w_times = "";
            my $line_w_errors = ""; # on AWS EC2 stderr goes into the temporary file, rescue it
            foreach (@timings) {
                if (split(/\t/) == 7) {
                    $line_w_times = $_;
                } else {
                    $line_w_errors = $_;
                }
            }
            if ($exit_code != 0) {
                if (length $line_w_errors) {
                    ERROR("Command failed: '$line_w_errors'");
                } else {
                    ERROR("Command failed");
                }
            }
            DEBUG("Read " . scalar(@timings) . " lines of time output, parsing '$line_w_times'");
            my @data = (0)x7; # Ellapsed, user, system, PCPU
            $line_w_times =~ s/%//g;
            @data = split(/\t/, $line_w_times) if (length $line_w_times);
            if (exists $config{"$label.teardown"}) {
                try { run($config{"$label.teardown"}); } 
                catch { WARN("$label.teardown command FAILED"); }
                finally { $teardown_exit_code = $IPC::System::Simple::EXITVAL; };
            } elsif (exists $config{"all.teardown"}) {
                try { run($config{"all.teardown"}); } 
                catch { WARN("all.teardown command FAILED"); }
                finally { $teardown_exit_code = $IPC::System::Simple::EXITVAL; };
            }
            push @data, ($exit_code, $host, $setup_exit_code, $teardown_exit_code);
            &save2db($sth_runtime, $label4run, @data) unless $dry_run;
            if ($rm_core_files) {
                no autodie; 
                unlink glob("core.*");
            }
            $pm->finish($exit_code) if defined $pm;
        }
    }
    $pm->wait_all_children if defined $pm;
    $dbh->disconnect();
}

sub collect_mem_usage
{
    open(my $vmstat_output, '-|', 'vmstat -s');
    my $total_memory = 0;
    my $used_memory = 0;
    while (<$vmstat_output>) {
        chomp;
        if (/(\d+) K total memory/) {
            $total_memory = $1;
        }
        if (/(\d+) K used memory/) {
            $used_memory = $1;
        }
    }
    close($vmstat_output);
    my $retval = INVALID_SYSINFO;
    $retval = ($used_memory*100.)/($total_memory*1.) if ($total_memory > 0);
    return $retval;
}

sub collect_cpu_usage
{
    open(my $top_output, '-|', 'top -bn1');
    my $retval = INVALID_SYSINFO;
    while (<$top_output>) {
        if (/^%/) {
            chomp;
            my @F = split;
            next unless (scalar(@F) > 8);
            next unless ($F[7] =~ /\d+.\d+/);
            $retval = 100.0 - $F[7];
            last;
        }
    }
    close($top_output);
    return $retval;
}


# Attempt multiple retries to save data in SQLite, to support multiple
# processes
sub save2db
{
    use constant MAX_RETRIES => 5;
    use constant SECS2SLEEP => 1;
    my $attempts = 0;
    my $sth = shift;
    my $label = shift;
    my @data = @_;
    while ($attempts < MAX_RETRIES) {
        try { 
            $sth->execute($label, @data); 
            $attempts = MAX_RETRIES + 1;
        } catch { 
            $attempts++;
            sleep(SECS2SLEEP);
        };
    }
}

# Initializes the logging for this script, defaulting to STDERR or the
# optionally provided logfile
sub init_logging
{
    my ($logfile, $verbose) = @_;
    my $opts = {level=>verbosity2threshold($verbose)};
    $opts->{file} = ">>$logfile" if (length $logfile);
    Log::Log4perl->easy_init($opts);
}

# Converts the verbosity flag to Log4perl logging levels
sub verbosity2threshold
{
    my $verbose = shift;
    my $retval = $OFF;
    if ($verbose == 1) {
        $retval = $WARN;
    } elsif ($verbose == 2) {
        $retval = $INFO;
    } elsif ($verbose == 3) {
        $retval = $DEBUG; 
    } elsif ($verbose >= 4) {
        $retval = $TRACE;
    }
    return $retval;
}

# Wrapper function to system that logs commands and throws an exception
# in case of failure
sub run
{
    use autodie qw(system);
    my $cmd = shift;
    TRACE($cmd);
    system($cmd) unless $dry_run;
}

# Connects to an SQLite database provided as its first argument
sub connect_to_sqlite 
{
    use DBI;
    my $sqlite_db = shift;
    my $data_source = "dbi:SQLite:$sqlite_db";
    my $dbh = undef;
    eval {
        $dbh = DBI->connect("$data_source", '', '',
                               { RaiseError => 1, AutoCommit => 1 });
        DEBUG("Connect to database server $data_source: OK");
    };
    LOGDIE("Failed to connect to database: $@") if ($@);
    return $dbh;
}

__END__

=head1 NAME

B<driver.pl> - Main driver script to run the timing experiments and record the
results in database

=head1 SYNOPSIS

driver.pl [options]

=head1 ARGUMENTS

=over

=item B<-db>

Database file name (default: data/timings.db)

=item B<-cmds>

Tab delimited file containing captions and commands to run (default:
etc/cmds.tab)

=item B<-repeats>

Number of times to run each command (default: 1)

=item B<-parallel>

Run commands in parallel (default: false). Disables -repeats.

=item B<-skip_failures>

Skip command on after any failure (default: false)

=item B<-rm_core_files>

Remove any core files created (default: false)

=item B<-verbose>

Produce verbose output (default: false)

=item B<-dry_run>

Do not run any commands, implies -verbose (default: false)

=item B<-logfile>

File name to write log to (default: driver.log)

=item B<-help>, B<-?>

Displays this man page.

=back

=head1 AUTHOR

Christiam Camacho (camacho@ncbi.nlm.nih.gov)

=cut

