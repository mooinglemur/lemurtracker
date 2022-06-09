#!/bin/env perl

use v5.16;
use warnings;
use strict;
use Data::Dumper;
use Math::Round qw(round);

my $a4_reference_freq = 440;

# This extrapolates the frequencies of the the 128 midi notes, 0-127
# plus an extra one to calculate deltas

my @notes = (
    (reverse map { $a4_reference_freq / ((2**(1/12))**$_) } (0..69)),
    map { $a4_reference_freq * ((2**(1/12))**$_) } (1..59)
);

# Turn them into PSG frequencies

my @psgfreqs = (
    map { $_ / (48828.125 / (2**17)) } @notes[0..127]
);

my @delta64 = (
    map { $notes[$_+1] - $notes[$_] } (0..127)
);

print "psgnote_lo: .byte ";
say join(",",map { sprintf("\$%02x",round($_) % 256) } @psgfreqs);

print "psgnote_hi: .byte ";
say join(",",map { sprintf("\$%02x",round($_/256)) } @psgfreqs);

print "psgdelta_sub: .byte ";
say join(",",map { sprintf("\$%02x",round($_*4) % 256) } @delta64);

print "psgdelta: .byte ";
say join(",",map { sprintf("\$%02x",round($_/64)) } @delta64);
