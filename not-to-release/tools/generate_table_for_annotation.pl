#!/usr/bin/env perl
# Převede soubor CoNLL-U do formátu, který je sice podobný, ale rysy jsou rozepsané do samostatných sloupců.
# Copyright © 2016 Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL

use utf8;
use open ':utf8';
binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

while(<>)
{
    if(m/^\d+\t/)
    {
        s/\r?\n$//;
        my @fields = split(/\t/, $_);
        my @features = split(/\|/, $fields[5]);
        my %features;
        foreach my $fpair (@features)
        {
            if($fpair =~ m/^(.+?)=(.+)$/)
            {
                $features{$1} = $2;
            }
        }
        my @fnames = ('Gender', 'Animacy', 'Number', 'Case', 'Degree', 'Person', 'VerbForm', 'Mood', 'Tense', 'Voice', 'Negative', 'PronType', 'Reflex', 'Poss', 'Gender[psor]', 'Number[psor]', 'NumType', 'VerbType', 'AdvType', 'Abbr', 'Hyph');
        my @values = map {my $x = $features{$_} // '_'; delete($features{$_}); $x} @fnames;
        # Sanity check: Are there any features that we do not export?
        my @remaining_features = keys(%features);
        if(scalar(@remaining_features)>0)
        {
            print STDERR ("Features not exported: ", join(', ', @remaining_features), "\n");
        }
        splice(@fields, 4, 1, @values);
        if($fields[3] =~ m/^(NUM|PUNCT)$/)
        {
            $fields[1] =~ s/"/""/g; # "
            $fields[1] = '"'.$fields[1].'"';
        }
        $_ = join("\t", @fields)."\n";
    }
    print;
}
