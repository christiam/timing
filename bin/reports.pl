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
my $dump = 0;
my $dry_run = 0;
my $verbose = 0;
my $logfile = "";
my $help_requested = 0;
GetOptions("db=s"           => \$dbname,
           "label=s"        => \@labels,
           "dump"           => \$dump,
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
    if (@labels == 1 and $labels[0] eq 'all') {
        @labels = get_all_labels($dbh);
    }
    foreach (@labels) {
        my $sql = "select ellapsed_time from runtime where label like '$_-%'";
        TRACE($sql);
        my @result = map { $_ = $_->[0] } @{ $dbh->selectall_arrayref($sql) };
        if (@result == 0) {
            $sql = "select ellapsed_time from runtime where label == '$_'";
            @result = map { $_ = $_->[0] } @{ $dbh->selectall_arrayref($sql) };
        }
        DEBUG(join(" ", $_, @result));

        my $stat = Statistics::Descriptive::Full->new();
        $stat->add_data(@result);
        $data{$_} = $stat;
    }


    $\ = "\n", $, = "\t";
    foreach (@labels) {
        if ($dump) {
            print $_, $data{$_}->get_data();
        } else {
            print $_, 
                "median", $data{$_}->median(), 
                "mean", $data{$_}->mean(), 
                "min", $data{$_}->min(), 
                "max", $data{$_}->max(),
                "stddev", $data{$_}->standard_deviation();
        }
    }
}

sub get_all_labels
{
    use List::MoreUtils qw(uniq);
    my $dbh = shift;
    my $sql = "select distinct(label) from runtime";
    my @array = map { $_ = $_->[0] } @{ $dbh->selectall_arrayref($sql) };
    s/-\d+$// foreach @array;   # drop the repeat number, if any
    return uniq @array;
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

B<reports.pl> - Produce reports from timing database (for ellapsed_time)

=head1 SYNOPSIS

reports.pl [options] -label <test-case> [-label <test-case> ... ]

=head1 ARGUMENTS

=over

=item B<-label>

Label from the database to display report for. Can be the keyword 'all', which
shows summary information for all labels in database.

=item B<-dump>
Shows the raw data for the requested label(s).

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

