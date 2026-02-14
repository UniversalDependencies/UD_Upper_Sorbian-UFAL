#!/usr/bin/env perl
# Reads CoNLL-U file manually segmented to sentences.
# Inserts a comment with sentence id before every sentence; uses and removes paragraph ids if present.
# Assumes that there are no other comments and inserts the comment right before the first token.
# Also assumes that there are no multi-word tokens yet, i.e. the sentence cannot start with '1-2'.
# Normalizes word numbering inside every sentence. Assumes there are no references to word indices yet, such as the HEAD column.

use utf8;
use open ':utf8';
binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');

my %hash;
my @sentence;
while(<>)
{
    push(@sentence, $_);
    if(m/^\s*$/)
    {
        my $sentence = join(' ', map {my @f = split(/\t/, $_); $f[1]} (grep {m/^\d+\t/} (@sentence)));
        unless(exists($hash{$sentence}))
        {
            print(join('', @sentence));
        }
        $hash{$sentence}++;
        @sentence = ();
    }
}
