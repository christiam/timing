#!/usr/bin/env perl
use strict;
use warnings;
use Log::Log4perl qw(:easy);
use Getopt::Long;
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
$verbose = 1 if ($dry_run and $verbose == 0);

try {
    init_logging($logfile, $verbose);
    main();
} catch {
    LOGDIE("Caught exception: $_");
};

sub main
{
    $ENV{TIME} = "%e\t%U\t%S\t%P";
    open my $fh, "<", $cmds;
    while (<$fh>) {
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
            my $time_output_file = "$label4run.time.out";
            my $cmd = "/usr/bin/time -o $time_output_file $cmd2time";
            run($cmd);
            open my $time_output, "<", $time_output_file;
            while (<$time_output>) {
                chomp;
                s/%//g;
                my @data = split(/\t/);
                $cmd = "sqlite3 $dbname 'INSERT INTO runtime VALUES(\"$label4run\",";
                $cmd .= sprintf("\"%f\",\"%f\",\"%f\",\"%d\");'", @data);
                run($cmd);
            }
            close($time_output);
            unlink $time_output_file;
        }
    }
    close($fh);
}

# Initialize logging function so that it uses increasing log levels
sub init_logging 
{
    my ($logfile, $verbose) = @_;
    my $level = $WARN;
    my $layout = '%d %m%n';
    if ($verbose == 1) {
        $level = $INFO;
    } elsif ($verbose == 2) {
        $level = $DEBUG;
        $layout = '%d [%8P] %6p %m%n';
    } elsif ($verbose >= 3) {
        $level = $TRACE;
        $layout = '%d [%8P] %6p %F:%L %m%n';
    }
    Log::Log4perl->easy_init({ 
        level => $level, 
        file => ">>$logfile",
        layout => $layout
    });
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

B<bin/driver.pl> - What this script does

=head1 SYNOPSIS

bin/driver.pl [options]

=head1 ARGUMENTS

=over

=item B<-verbose>, B<-v>

Produce verbose output (default: false)

=item B<-dry_run>

Do not run any commands, implies -verbose (default: false)

=item B<-logfile>

File name to write log to (default: driver.log)

=item B<-help>, B<-h>, B<-?>

Displays this man page.

=back

=head1 AUTHOR

Christiam Camacho (camacho@ncbi.nlm.nih.gov)

=cut

