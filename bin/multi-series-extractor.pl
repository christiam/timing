#!/usr/bin/env perl
use strict;
use warnings;

my %data;
my @TEST_CASES = qw(blastx_on_mesos blastx_standalone);
while (<>) {
    chomp;
    if (/^(.*)-(\d+)\|/) {
		my @fields = split(/\|/);
		if ($fields[5] == 0) {	# check exit code
			$data{$2}{$1} = $fields[1];	# save the ellapsed time
		}
        #print "saved time for $1 ", $data{$2}{$1}, "\n";
    } 
}

$\ = "\n", $, = "\t";
# N.B.: Produces data to be used by gnuplot >= 4.6 (this is used with set key autotitle columnhead)
print "Number of cores", @TEST_CASES;
foreach my $n (sort {$a<=>$b} keys %data) {
    my @times;
    foreach my $t (@TEST_CASES) {
        my $measurement = (exists($data{$n}{$t})) ? $data{$n}{$t} : "-";
        push @times, $measurement;
    }
    print $n, @times;
}
