#!/usr/bin/env perl
# Reads CoNLL-U file segmented to paragraphs. Inserts a comment with a paragraph id before every paragraph.
# Assumes that there are no other comments and inserts the comment right before the first token.
# Also assumes that there are no multi-word tokens yet, i.e. the paragraph cannot start with '1-2'.

use utf8;
use open ':utf8';
binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');

my $n = 0;
while(<>)
{
    if(m/^1\t/)
    {
        $n++;
        print("# par_id $n\n");
    }
    print;
}
