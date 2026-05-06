#!/usr/bin/env perl
# Převede hornolužické značky ze Sorokinova taggeru do Universal Dependencies (UPOS + features).
# Copyright © 2016 Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL

use utf8;
use open ':utf8';
binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');
use Lingua::Interset::Converter;

my $c = new Lingua::Interset::Converter ('from' => 'hsb::sorokin', 'to' => 'mul::uposf');
while(<>)
{
    if(m/^\d+\t/)
    {
        s/\r?\n$//;
        my @fields = split(/\t/, $_);
        my $source_tag = $fields[4];
        my $target_tag = $c->convert($source_tag);
        my ($upos, $ufeat) = split(/\t/, $target_tag);
        $fields[3] = $upos // '_';
        $fields[4] = '_';
        $fields[5] = $ufeat // 'X';
        my @misc = grep {!m/^AltTag/} (split(/\|/, $fields[9]));
        @misc = ('_') if(scalar(@misc)==0);
        $fields[9] = join('|', @misc);
        # Make sure that the HEAD column is numeric. Other tools may not digest the underscore character.
        $fields[6] = 0;
        $_ = join("\t", @fields)."\n";
    }
    print;
}
