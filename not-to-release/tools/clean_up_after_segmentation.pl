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

my $pid;
my $sn = 0;
my $new_sentence = 1;
my $ord;
while(<>)
{
    # Read current paragraph id but do not print it.
    if(m/^#\s*par_id\s*(\S+)/)
    {
        $pid = $1;
        $sn = 0;
        next;
    }
    # Check all token lines and normalize their numbering.
    if(m/^\d+\t/)
    {
        # Insert sentence id before every sentence.
        if($new_sentence)
        {
            $sn++;
            my $sid = "s$sn/hsb";
            $sid = 'p'.$pid.$sid if(defined($pid));
            print("# sent_id $sid\n");
            $new_sentence = 0;
            $ord = 1;
        }
        else
        {
            $ord++;
        }
        my @fields = split(/\t/, $_);
        $fields[0] = $ord;
        $_ = join("\t", @fields);
    }
    elsif(m/^\s*$/)
    {
        $new_sentence = 1;
    }
    print;
}
