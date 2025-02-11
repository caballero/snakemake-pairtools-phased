#!/usr/bin/perl
#
use strict;
use warnings;

$ARGV[5] or die "use merge_pairs.pl cis_pairs1 prefix1 cis_pairs2 prefix2 trans_pairs out_pairs\n";

my $cis1_file  = shift @ARGV;
my $hap1       = shift @ARGV;
my $cis2_file  = shift @ARGV;
my $hap2       = shift @ARGV;
my $trans_file = shift @ARGV;
my $out_file   = shift @ARGV;

open (my $out, ">", $out_file) or die "cannot write $out_file\n";

open (my $cis1,  "gunzip -c $cis1_file  |") or die "cannot read $cis1_file\n";
open (my $cis2,  "gunzip -c $cis2_file  |") or die "cannot read $cis2_file\n";
open (my $trans, "gunzip -c $trans_file |") or die "cannot read $trans_file\n";

warn "parsing $cis1_file\n";
while (<$cis1>) {
    if (/^#/) {
        print $out $_;
        next;
    }
    my @a = split (/\t/);
    $a[1] .= $hap1;
    $a[3] .= $hap1;
    print $out join "\t", @a;
}

warn "parsing $cis2_file\n";
while (<$cis2>) {
    next if (/^#/);
    my @a = split (/\t/);
    $a[1] .= $hap2;
    $a[3] .= $hap2;
    print $out join "\t", @a;
}

warn "parsing $trans_file\n";
while (<$trans>) {
    next if (/^#/);
    my @a = split (/\t/);
    $a[1] .= $hap1;
    $a[3] .= $hap2;
    print $out join "\t", @a;
}

close $out;
close $cis1;
close $cis2;
close $trans;

warn "all done\n";
