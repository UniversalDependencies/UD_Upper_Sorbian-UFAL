#!/usr/bin/env perl
# Reads a CoNLL-U file, detokenizes the text (based on the SpaceAfter=No attribute) and prints it.
# Sentences are assumed to be paragraphs and are separated by a blank line.

use utf8;
use open ':utf8';
binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');

while(<>)
{
    if(m/^\s*$/)
    {
        my $n = scalar(@sentence);
        my @tokens = map {my @f = split(/\t/, $_); ($f[0]==$n || $f[9] =~ m/SpaceAfter=No/) ? $f[1] : "$f[1] "} (@sentence);
        print(join('', @tokens), "\n\n");
        splice(@sentence);
    }
    else
    {
        push(@sentence, $_);
    }
}
