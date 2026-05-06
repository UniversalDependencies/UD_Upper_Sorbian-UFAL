#!/usr/bin/env perl
# Reads the result of merging tagger output with the original CoNLL-U file.
# There are now two word forms: original in FORM and tagger-modified in LEMMA. Most of the time they are identical.
# Also, there may be several tag suggestions per word.

use utf8;
use open ':utf8';
binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');

while(<>)
{
    s/\r?\n$//;
    unless(m/^\s*$/)
    {
        my @fields = split(/\t/, $_);
        my @misc;
        @misc = split(/\|/, $fields[9]) unless($fields[9] eq '_');
        # Remove tagger form from LEMMA.
        if($fields[2] ne $fields[1])
        {
            $fields[2] =~ s/\s+/_/g;
            push(@misc, "TaggerForm=$fields[2]");
        }
        $fields[2] = '_';
        # Keep only the best tag in XPOS.
        my @tags = split(/, /, $fields[3]);
        if(scalar(@tags)>1)
        {
            $fields[3] = $tags[0];
            for(my $i = 1; $i<=$#tags; $i++)
            {
                push(@misc, "AltTag$i=$tags[$i]");
            }
        }
        # Move the tag from UPOS to XPOS.
        $fields[4] = $fields[3];
        $fields[3] = '_';
        $fields[9] = join('|', @misc) if(scalar(@misc)>0);
        # Make sure that the HEAD column is numeric. Other tools may not digest the underscore character.
        $fields[6] = 0;
        $_ = join("\t", @fields);
    }
    print("$_\n");
}
