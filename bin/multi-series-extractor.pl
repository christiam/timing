#!/usr/bin/env perl
use strict;
use warnings;

my %data;
my @QUERIES = qw(1336q 15795q 139340q);
while (<>) {
    chomp;
    if (/^(\d+q)-(\d+)\|/) {
        $data{$2}{$1} = [ split(/\|/) ] ->[1];
        #print "saved time for $1 ", $data{$2}{$1}, "\n";
    } 
}

$\ = "\n", $, = "\t";
# N.B.: Produces data to be used by gnuplot >= 4.6 (this is used with set key autotitle columnhead)
print "Number of cores", "1336 queries", "15795 queries", "139340 queries";
foreach my $num_cores (sort {$a<=>$b} keys %data) {
    my @times;
    foreach my $q (@QUERIES) {
        push @times, $data{$num_cores}{$q};
    }
    print $num_cores, @times;
}
