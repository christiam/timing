#!/usr/bin/env perl
# Takes a CSV file with labels and values, adds up the values and outputs a
# 2-column list: label,ratio
use strict;
use warnings;
my %data;
while (<>) {
    chomp;
    next if (/^#/);
    my @F = split(/,/);
    next unless (@F > 1);
    my $sum = 0.0;
    #my $max_idx = 3; # use this if only some columns need to be used
    my $max_idx = scalar(@F);
    for (my $i = 1; $i < $max_idx; $i++) {
        $sum += $F[$i];
    }
    $data{$F[0]} = $sum;
}
my ($min_data, $min_label);
foreach (keys %data) {
    $min_data = $data{$_};
    $min_label = $_;
    last;
}
foreach (keys %data) {
    if ($data{$_} < $data{$min_label}) {
        $min_label = $_;
        $min_data = $data{$_};
    }
}
$\ = "\n", $, = ",";
print $min_label, 1;
foreach (keys %data) {
    next if ($_ eq $min_label);
    print $_, sprintf("%.2f", ($data{$_}/$min_data));
}

