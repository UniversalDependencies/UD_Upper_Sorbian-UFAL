#!/usr/bin/env perl
# Removes extra columns that we introduced after Libre Office for double checking.
# Copyright © 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL

use utf8;
use open ':utf8';
binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

while(<>)
{
    s/\r?\n$//;
    if(m/^\d/)
    {
        my @f = split(/\t/, $_);
        if(scalar(@f)>10)
        {
            splice(@f, 10);
        }
        if(scalar(@f)<10)
        {
            print STDERR ("WARNING! Line starts with number but has fewer than 10 columns.\n");
        }
        $_ = join("\t", @f);
    }
    print("$_\n");
}
