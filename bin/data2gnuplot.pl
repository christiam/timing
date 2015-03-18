#!/usr/bin/env perl
use strict;
use warnings;

my %data;
my @QUERIES = qw(AADG AAFX AKNF);
while (<>) {
    chomp;
    if (/^(\w+)_spark_(\w+)-(\d+)\|/) {
        $data{$1}{$2}{'spark'}{$3} = [ split(/\|/) ] ->[1];
    } elsif (/^(\w+)_(\w+)-(\d+)\|/) {
        $data{$1}{$2}{'local'}{$3} = [ split(/\|/) ] ->[1];
    }
}

# N.B.: Produces data to be used by gnuplot >= 4.6
$\ = "\n", $, = "\t";
my $data_index = 0;
foreach my $p (qw(blastn blastx)) {
    foreach my $q (@QUERIES) {
        print "# $data_index: repeated $p of $q (time in secs)";
        print "run-number", "spark", "local";
        foreach my $try (1 .. 3) {
            print $try, $data{$p}{$q}{'spark'}{$try},
                        $data{$p}{$q}{'local'}{$try};
        }
        $data_index++, print "\n";
    }
}
