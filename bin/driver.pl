#!/usr/bin/env perl
use strict;
use warnings;
use Log::Log4perl qw(:easy);
use Getopt::Long;
use File::Slurp;
use File::Temp;
use Pod::Usage;
use Try::Tiny;
use autodie;

my $dbname = "data/timings.db";
my $cmds = "etc/cmds.tab";
my $num_repeats = 1;
my $dry_run = 0;
my $verbose = 0;
(my $logfile = $0) =~ s/.pl/.log/;
my $help_requested = 0;
GetOptions("db=s"           => \$dbname,
           "cmds=s"         => \$cmds,
           "repeats=i"      => \$num_repeats,
           "verbose|v+"     => \$verbose,
           "dry_run"        => \$dry_run,
           "logfile=s"      => \$logfile,
           "help|?"         => \$help_requested) || pod2usage(2);
pod2usage(-verbose=>2) if ($help_requested);
pod2usage("Missing command file") unless (-s $cmds);
pod2usage("Missing database") unless (-s $dbname);
pod2usage("Invalid number of repeats") unless ($num_repeats > 0);
$verbose = 5 if ($dry_run and $verbose == 0);
Log::Log4perl->easy_init({level=>verbosity2threshold($verbose),$file=>">>$logfile"});

try {
    main();
} catch {
    LOGDIE("Caught exception: $_");
};

sub main
{
    $ENV{TIME} = "%e\t%U\t%S\t%P";
    foreach (read_file($cmds)) {
        next if (/^#/);
        chomp;
        my @F = split(/\t/);
        die "Invalid input: tab separated label and command expected" if (@F != 2);
        my $label = $F[0];
        my $cmd2time = $F[1];
        for (my $run_number = 0; $run_number < $num_repeats; $run_number++) {
            my $label4run = $label . "-" . ($run_number+1);
            if ($num_repeats == 1) {
                $label4run = $label;
            }
            my $tmp_fh = File::Temp->new();
            my $cmd = "/usr/bin/time -o $tmp_fh $cmd2time";
            run($cmd);
            chomp(my $time_output = read_file($tmp_fh->filename));
            $time_output =~ s/%//g;
            $cmd = "sqlite3 $dbname 'INSERT INTO runtime VALUES(\"$label4run\",";
            $cmd .= sprintf("\"%f\",\"%f\",\"%f\",\"%d\");'", split(/\t/));
            run($cmd);
        }
    }
}

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

### # Wrapper function to system that logs commands
### sub run
### {
###     use IPC::System::Simple qw(EXIT_ANY runx);
###     my $cmd = shift;
###     TRACE($cmd);
###     my @args = split(/ /, $cmd);
###     my $program = shift @args;
###     my $retval = $dry_run ? 0 : runx(EXIT_ANY, $program, @args);
###     TRACE("Exit code = $retval");
###     return $retval;
### }
### 
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

