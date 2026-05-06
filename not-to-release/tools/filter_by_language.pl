#!/usr/bin/env perl
# Vyfiltruje ze souboru CoNLL-U pouze věty jednoho konkrétního jazyka, který pozná podle konce sent_id.
# Copyright © 2016 Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL

use utf8;
use open ':utf8';
binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

my $desired_language = shift(@ARGV);
die("First argument must be a language code") if(!defined($desired_language) || $desired_language !~ m/^[a-z]+$/);
my $sentence = '';
my $language = '';
while(<>)
{
    if(m:^\#\s+sent_id\s+.+/([a-z]+)$:)
    {
        $language = $1;
    }
    $sentence .= $_;
    if(m/^\s*$/)
    {
        if($language eq $desired_language)
        {
            print($sentence);
        }
        $sentence = '';
    }
}
