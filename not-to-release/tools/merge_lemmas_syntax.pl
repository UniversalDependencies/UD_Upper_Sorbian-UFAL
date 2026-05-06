#!/usr/bin/env perl
# Spojí ruční lemmatizaci od Anji s ruční syntaxí od Dana (tyto anotace probíhaly souběžně).
# Copyright © 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL

use utf8;
use open ':utf8';
binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

my $lemmafile = $ARGV[0];
my $syntaxfile = $ARGV[1];
open(LEMMA, $lemmafile) or die("Cannot read $lemmafile: $!");
open(SYNTAX, $syntaxfile) or die("Cannot read $syntaxfile: $!");
my $i_line = 0; # first line will have 1 so we can locate it in the editor
my $j_line = 0; # the two files do not have identical number of lines
while(my $lline = <LEMMA>)
{
    my $sline = <SYNTAX>;
    $i_line++;
    $j_line++;
    chomp($lline);
    chomp($sline);
    $lline =~ s/[\r\n]+$//s;
    $sline =~ s/[\r\n]+$//s;
    if($lline =~ m/^\d/)
    {
        my @lf = split(/\t/, $lline);
        my @sf = split(/\t/, $sline);
        # Sanity check: word ids and word forms must be identical.
        if($lf[0] ne $sf[0])
        {
            die("$i_line/$j_line FATAL: Word id mismatch: $lf[0] != $sf[0]");
        }
        if($lf[1] ne $sf[1])
        {
            # There is one word form fix in the syntax file.
            $lf[1] = $sf[1];
            print STDERR ("$i_line/$j_line WARNING: Word form mismatch: $lf[1] != $sf[1]\n");
        }
        # Check what has been fixed in morphology on either side.
        if($lf[2] ne $sf[2])
        {
            # Some lemmas (especially punctuation) has been replaced by 0 in Libre Office but they are available in the syntax file.
            if($lf[2] eq '0' && $sf[2] ne '' && $sf[2] ne '_')
            {
                $lf[2] = $sf[2];
            }
            # It is expected that the lemma file contains lemmas that the syntax file doesn't. Don't report such cases.
            elsif(!($lf[2] ne '_' && $sf[2] eq '_'))
            {
                # The remaining lemma mismatches are fixes in the syntax file.
                if($sf[2] ne '_')
                {
                    $lf[2] = $sf[2];
                }
                #print STDERR ("$i_line/$j_line Lemma mismatch: $lf[2] != $sf[2]\n");
            }
        }
        # Ignore UD v1-v2 mismatch between CONJ and CCONJ.
        my $lupos = $lf[3];
        $lupos = 'CCONJ' if($lupos eq 'CONJ');
        if($lupos ne $sf[3])
        {
            # "Kaž" has been retagged from SCONJ to ADV in Anja's file.
            if(!($lf[1] =~ m/^kaž$/i && $lf[3] eq 'ADV'))
            {
                # Various tags have been fixed in Tred, especially AUX for copula verbs.
                $lf[3] = $sf[3];
            }
        }
        # The syntactic file lost some features because of UD v1-v2 incompatibility: Animacy, Negative.
        my $lfeats = $lf[5];
        $lfeats =~ s/(Animacy|Negative)=(.+?)\|//g;
        $lfeats =~ s/^Negative=[^\|]+$/_/;
        # Pure numbers ("6") have NumType=Card in the syntax file and nothing in the lemma file.
        if($lfeats eq '_' && $sf[5] eq 'NumType=Card')
        {
            $lf[5] = $sf[5];
        }
        elsif($lfeats ne $sf[5])
        {
            print STDERR ("$i_line/$j_line Features mismatch: $lf[5] != $sf[5]\n");
        }
        # Copy syntax from the syntax file.
        $lf[6] = $sf[6];
        $lf[7] = $sf[7];
        # Copy also the MISC column (SpaceAfter=No) from the syntax file; it has been lost in the Libre Office annotation.
        $lf[9] = $sf[9];
        print(join("\t", @lf), "\n");
    }
    # Sentence-level comments with sentence ids.
    # Lemma file format:  # sent_id p1s1/hsb
    # Syntax file format: # sent_id = s1/hsb
    elsif($lline =~ m/^\#\s*sent_id\s+(.+)$/)
    {
        my $lsid = $1;
        my $ssid = $1;
        if($sline =~ m/^\#\s*sent_id\s*=\s*(.+)$/)
        {
            $ssid = $1;
        }
        else
        {
            print STDERR ("WARNING! Sentence id expected but not found in the syntax file.\n");
        }
        # The sentence ids end with the language code ("/hsb") but we no longer want to have it there.
        $lsid =~ s:/.*::;
        $ssid =~ s:/.*::;
        # The id from the lemma file contains the paragraph id, which has been lost in the syntax file.
        # Keep the id from the lemma file but use the new " = " notation.
        my $outline = "# sent_id = $lsid";
        # The syntax file contains text comments, which immediately follow after sentence ids. Include them.
        $sline = <SYNTAX>;
        chomp($sline);
        $sline =~ s/[\r\n]+$//s;
        $j_line++;
        if($sline =~ m/^\#\s*text\s*=\s*(.+)$/)
        {
            $outline .= "\n# text = $1";
        }
        else
        {
            # We cannot continue if the two files are out of sync.
            die("FATAL: Text comment expected but not found in the syntax file.\n");
        }
        print("$outline\n");
    }
    # The rest is just the empty lines after sentences.
    else
    {
        print("\n");
    }
}
close(LEMMA);
close(SYNTAX);
