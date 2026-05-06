#!/usr/bin/env perl
# Slije výstup hornolužického taggeru s původním textem v CoNLL.
# Copyright © 2016 Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL

use utf8;
use open ':utf8';
binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

my $conllfile = $ARGV[0]; #'hsb-filtered-spaceafter.conllu';
my $taggedfile = $ARGV[1]; #'hsb-filtered-tagged.txt';
open(CONLL, $conllfile) or die("Cannot read $conllfile: $!");
open(TAGGED, $taggedfile) or die("Cannot read $taggedfile: $!");
my $buffer;
my $tkeep;
my $conll_line;
my $tagged_line;
my @tagged_fields;
my %c2tmap =
(
    '«' => '"',
    '»' => '"',
    '…' => '...'
);
while(<CONLL>)
{
    $conll_line = $_;
    if($conll_line =~ m/^\s*$/)
    {
        print($conll_line);
    }
    else
    {
        $conll_line =~ s/\r?\n$//;
        my @conll_fields = split(/\t/, $conll_line);
        # Unfortunately our tokenizer is not identical to that of the tagger (which uses the Stanford tokenizer).
        # For instance, we produce "syrisko - arabska", they produce "syrisko-arabska".
        if(defined($buffer))
        {
            $buffer .= $conll_fields[1];
            ###!!! singularity
            if($conll_fields[1] =~ m/^\d+KM$/)
            {
                $tagged_fields[0] .= 'KM';
                $tagged_line = <TAGGED>;
            }
            elsif($conll_fields[1] eq 'Budyšin' && $tagged_fields[0] eq 'Bautzen/Budy')
            {
                $tagged_fields[0] .= 'šin';
                $tagged_line = <TAGGED>;
            }
            elsif($conll_fields[1] eq 'hišće' && $tagged_fields[0] eq 'wjace/hi')
            {
                $tagged_fields[0] .= 'šće';
                $tagged_line = <TAGGED>;
            }
            if($buffer eq $tagged_fields[0])
            {
                $conll_fields[2] = $tagged_fields[0];
                $conll_fields[3] = $tagged_fields[1];
                $buffer = undef;
            }
        }
        else # no buffer at the moment
        {
            if($tkeep)
            {
                $tkeep = undef;
            }
            else
            {
                $tagged_line = <TAGGED>;
                $tagged_line =~ s/\r?\n$//;
                @tagged_fields = split(/\t/, $tagged_line);
                # The tagger escapes certain characters.
                $tagged_fields[0] =~ s-\\/-/-g;
                $tagged_fields[0] =~ s-\\\*-*-g;
                ###!!! a singularity?
                $tagged_line = <TAGGED> if($tagged_fields[0] eq 'Ft.');
            }
            if($conll_fields[1] eq $tagged_fields[0] || $c2tmap{$conll_fields[1]} eq $tagged_fields[0])
            {
                $conll_fields[2] = $tagged_fields[0];
                $conll_fields[3] = $tagged_fields[1];
            }
            elsif($conll_fields[1] eq 'ಕರ್ನಾಟಕ')
            {
                $tagged_line = <TAGGED>;
                $tagged_line = <TAGGED>;
                $tagged_line = <TAGGED>;
                $tagged_line = <TAGGED>;
            }
            else
            {
                #print("!!!!!!!!!!!!!!!!!!!!\tCONLL='$conll_fields[1]'\tTAGGED='$tagged_fields[0]'\n");
                $buffer = $conll_fields[1];
            }
        }
        print(join("\t", @conll_fields), "\n");
    }
}
close(CONLL);
close(TAGGED);
