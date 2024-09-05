#!/usr/bin/perl

use strict;
use warnings;

$ARGV[3] or die "Usage: $0 <reference.fasta> <snps.vcf> <nmasked.out> <snp.table>\n";
# get inputs and outputs
my $ref = $ARGV[0];
my $vcf = $ARGV[1];
my $out = $ARGV[2];
my $snp = $ARGV[3];

# load reference
warn "loading genome from $ref\n";
my %genome;
my %ids;
my $chr_cnt = 0;
my $refh;

if ($ref =~ /\.gz$/) { 
    open $refh, '-|', "zcat $ref" or die "Could not open $ref: $!\n" 
} else { 
    open $refh, '<', $ref or die "Could not open $ref: $!\n";
}
while (<$refh>) {
    chomp;
    if (/^>(\w+)/) {
        $genome{$1} = '';
        $ids{$1} = $_;
        $chr_cnt++;
    } else {
        $genome{$1} .= $_;
    }
}
close $refh;
warn "found $chr_cnt chromosomes\n";

# load snps
warn "loading snps from $vcf\n";
my %snps;
my $snp_num = 0;
my $vcfh;
my $snph;
if ($vcf =~ /\.gz$/) {
    open $vcfh, '-|', "zcat $vcf" or die "Could not open $vcf: $!\n";
} else {
    open $vcfh, '<', $vcf or die "Could not open $vcf: $!\n";
}
open $snph, '>', $snp or die "Could not open $snp: $!\n";

print join "\t", "ID", "Chr", "Position", "SNP value", "Ref/SNP\n";
while (<$vcfh>) {
    next if /^#/;
    chomp;
    my @a = split /\t/, $_;
    my $chr = $a[0];
    my $pos = $a[1];
    my $ref = $a[3];
    my $alt = $a[4];
    my $g1  = $a[9];
    my $g2  = $a[10];
    my $s1  = undef;
    my $s2  = undef;
    maskGenome($chr, $pos, $ref);

    if ($g1 =~ m|0/0| and $g2 =~ m|1/1|) {
        $s1 = $ref;
        $s2 = $alt;
    } elsif ($g1 =~ m|1/1| and $g2 =~ m|0/0|) {
        $s1 = $alt;
        $s2 = $ref;
    } elsif ($g1 =~ m|1/1| and $g2 =~ m|1/1|) {
        $s1 = $alt;
        $s2 = $alt;
    } else {
        warn "Unsupported genotype: $_\n";
        next;
    }
    $snp_num++;

    print $snph join "\t", "snp_$snp_num", $chr, $pos, 1, "$s1/$s2\n";
}
close $vcfh;
close $snph;

warn "found $snp_num snps\n";

# write n-masked genome output
warn "writing n-masked genome to $out\n";
open my $outh, '>', $out or die "Could not open $out: $!\n";
for my $chr (sort keys %genome) {
    my $id = $ids{$chr};
    print $outh ">$id\n";
    while ($genome{$chr}) {
        print $outh substr($genome{$chr}, 0, 80);
        print $outh "\n";
        substr($genome{$chr}, 0, 80) = '';
    }
}
close $outh;
warn "done\n";

# Replace the reference base at the given position with 'N' if it matches the given reference base.
sub maskGenome {
    my ($chr, $pos, $ref) = @_;
    my $obs = substr($genome{$chr}, $pos - 1, 1);
    if ($obs eq $ref) {
        substr($genome{$chr}, $pos - 1, 1) = 'N';
    }
    else {
        warn "Unexpected reference base: $chr:$pos REF=$ref OBS=$obs\n";
    }
}