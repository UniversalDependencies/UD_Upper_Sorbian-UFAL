#!/usr/bin/env perl
# Reads the CoNLL-U file with tags by Daniil Sorokin, collects and prints the list of used tags.

use utf8;
use open ':utf8';
binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');

my %tags;
my %features;
while(<>)
{
    s/\r?\n$//;
    if(m/^\d+\t/)
    {
        my @fields = split(/\t/, $_);
        # The main tag is in the XPOS column.
        # There may be additional possible tags in the MISC column.
        my @misc;
        @misc = split(/\|/, $fields[9]) unless($fields[9] eq '_');
        @misc = map {s/^AltTag\d+=//; $_} (grep {m/^AltTag\d+=/} (@misc));
        foreach my $tag ($fields[4], @misc)
        {
            $tags{$tag}++;
            my @features = split(/-/, $tag);
            foreach my $feature (@features)
            {
                $features{$feature}++;
            }
        }
    }
}
print("LIST OF FULL TAGS\n");
my @tags = sort(keys(%tags));
foreach my $tag (@tags)
{
    print("$tag\t$tags{$tag}\n");
}
print("TOTAL ", scalar(@tags), " TAGS\n\n");
print("LIST OF INDIVIDUAL FEATURES\n");
my @features = sort(keys(%features));
foreach my $feature (@features)
{
    print("$feature\t$features{$feature}\n");
}
print("TOTAL ", scalar(@features), " FEATURES\n");
