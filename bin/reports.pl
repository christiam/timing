#!/usr/bin/env perl
use strict;
use warnings;
use Log::Log4perl qw(:easy);
use Getopt::Long;
use File::Slurp;
use Pod::Usage;
use Try::Tiny;
use DBI;
use Statistics::Descriptive;
use autodie;

my $dbname = "data/timings.db";
my @labels;
my $showall = 0;
my $dry_run = 0;
my $verbose = 0;
my $logfile = "";
my $help_requested = 0;
GetOptions("db=s"           => \$dbname,
           "label=s"        => \@labels,
           "showall"        => \$showall,
           "verbose|v+"     => \$verbose,
           "dry_run"        => \$dry_run,
           "logfile=s"      => \$logfile,
           "help|?"         => \$help_requested) || pod2usage(2);
pod2usage(-verbose=>2) if ($help_requested);
pod2usage("Missing database") unless (-s $dbname);
pod2usage("Missing labels") unless (@labels);
$verbose = 5 if ($dry_run and $verbose == 0);

try {
    init_logging($logfile, $verbose);
    main();
} catch {
    LOGDIE("Caught exception: $_");
};

sub main
{
    my $dbh = connect_to_sqlite($dbname);
    my %data;
    foreach (@labels) {
        my $sql = "select ellapsed_time from runtime where label like '$_-%'";
        TRACE($sql);
        my @result = map { $_ = $_->[0] } @{ $dbh->selectall_arrayref($sql) };
        DEBUG(join(" ", $_, @result));

        my $stat = Statistics::Descriptive::Full->new();
        $stat->add_data(@result);
        $data{$_} = $stat;
    }


    $\ = "\n", $, = " ";
    foreach (@labels) {
        if ($showall) {
            print $_, $data{$_}->get_data();
        } else {
            print $_, 
                "median", $data{$_}->median(), 
                "mean", $data{$_}->mean(), 
                "min", $data{$_}->min(), 
                "max", $data{$_}->max(); 
        }
    }
}

# Connects to an SQLite database provided as its first argument
sub connect_to_sqlite 
{
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

__END__

=head1 NAME

B<reports.pl> - Produce reports from timing database

=head1 SYNOPSIS

reports.pl [options] -label <test-case> [-label <test-case> ... ]

=head1 ARGUMENTS

=over

=item B<-db>

Database file name (default: data/timings.db)

=item B<-verbose>

Produce verbose output (default: false)

=item B<-dry_run>

Do not run any commands, implies -verbose (default: false)

=item B<-help>, B<-?>

Displays this man page.

=back

=head1 AUTHOR

Christiam Camacho (camacho@ncbi.nlm.nih.gov)

=cut

