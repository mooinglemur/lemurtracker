#!/bin/env perl

# Usage: ./generate_psg_lut.pl > psgfreq.inc

use v5.16;
use warnings;
use strict;
use Data::Dumper;
use Math::Round qw(round);

my $a4_reference_freq = 440;

# These are 1/768 of an octave, or 1/64 of a semitone
# so that we can fine-pitch the PSG like the YM2151
# linear by note pitch rather than linear by frequency

# 1.5kB of lookup tables is unfortunately large,
# and as it turns out, cumbersome to look things up in.

my @freqs = (
    map { ($a4_reference_freq * 16) * ((2**(1/768))**$_) } (0..959)
);

# Turn them into PSG frequencies

my @psgfreqs = (
    map { $_ / (48828.125 / (2**17)) } @freqs[192..959]
);

my @notenames = qw(c cs d ds e f fs g gs a as b);

    say "noteindex:";

for my $note (@notenames) {
    say "noteindex_${note}: .word psgfreq_${note}_lo,psgfreq_${note}_hi";
}

for (my ($i,$j)=(0,0);$i < 768;$i += 64,$j++) {
    print "psgfreq_${notenames[$j]}_lo: .byte ";
    say join(",",map { sprintf("\$%02x",round($_) % 256) } @psgfreqs[$i..$i+63]);
}

for (my ($i,$j)=(0,0);$i < 768;$i += 64,$j++) {
    print "psgfreq_${notenames[$j]}_hi: .byte ";
    say join(",",map { sprintf("\$%02x",int($_/256)) } @psgfreqs[$i..$i+63]);
}

# Now let's do the entire range of pure note frequencies

my @notes = ( # A-2 (A negative 2) onward, so we shift the start so that C-1 (C negative 1) is note 0
    map { ($a4_reference_freq / (2**6)) * ((2**(1/12))**$_) } (3..130)
);

my @psgnotefreqs = (
    map { $_ / (48828.125 / (2**17)) } @notes
);

print "psgfreq_notes_lo: .byte ";
say join(",",map { sprintf("\$%02x",round($_) % 256) } @psgnotefreqs);

print "psgfreq_notes_hi: .byte ";
say join(",",map { sprintf("\$%02x",int($_/256)) } @psgnotefreqs);


