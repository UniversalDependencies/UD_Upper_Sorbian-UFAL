#!/usr/bin/env perl
# Zkontroluje CSV soubor po ruční anotaci, že odpovídá vstupnímu souboru.
# Copyright © 2016 Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL

use utf8;
use open ':utf8';
binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

my $origfile = $ARGV[0];
my $annofile = $ARGV[1];
open(ORIG, $origfile) or die("Cannot read $origfile: $!");
open(ANNO, $annofile) or die("Cannot read $annofile: $!");
my %languages;
my $n_empty_lemmas = 0;
my $i_line = 0; # first line will have 1 so we can locate it in the editor
while(my $oline = <ORIG>)
{
    my $aline = <ANNO>;
    $i_line++;
    chomp($oline);
    chomp($aline);
    $oline =~ s/[\r\n]+$//s;
    $aline =~ s/[\r\n]+$//s;
    # Token lines may differ in all but the word id and form.
    if($oline =~ m/^\d/)
    {
        my @of = split(/\t/, $oline);
        my @af = split(/\t/, $aline);
        # The annotated word forms are sometimes (for some numbers and special characters) quoted. Remove the quotes.
        @af = map
        {
            my $x = $_;
            if($x =~ s/^"(.+)"$/$1/)
            {
                $x =~ s/""/"/g; #"
            }
            $x
        }
        (@af);
        # Some lines are damaged because of bad encoding of quotation marks.
        # An @af line is bad if it contains fewer than 30 columns.
        # Presumably the annotator was not able to edit the bad lines.
        # Thus we simply replace them with the pre-annotation line.
        if(scalar(@af)<30)
        {
            @af = @of;
        }
        else
        {
            if($of[0] ne $af[0])
            {
                print STDERR ("Word id mismatch: '$of[0]' --> '$af[0]'\n");
            }
            elsif($of[1] ne $af[1])
            {
                print STDERR ("Word form mismatch: '$of[1]' --> '$af[1]'\n");
                $af[1] = $of[1];
            }
            # Collapse the features back to one column. Note that we did not have the same set of columns in the two manual runs.
            my @fnames_run1 = ('Gender', 'Animacy', 'Number', 'Case', 'Degree', 'Person', 'VerbForm', 'Mood', 'Tense', 'Voice', 'PronType', 'Reflex', 'NumType', 'VerbType', 'AdpType', 'Abbr');
            my @fnames_run2 = ('Gender', 'Animacy', 'Number', 'Case', 'Degree', 'Person', 'VerbForm', 'Mood', 'Tense', 'Voice', 'Negative', 'PronType', 'Reflex', 'Poss', 'Gender[psor]', 'Number[psor]', 'NumType', 'VerbType', 'AdvType', 'Abbr', 'Hyph');
            my @fnames = @fnames_run2;
            my @flist;
            for(my $i = 0; $i <= $#fnames; $i++)
            {
                my $value = $af[$i+4];
                # "Imperfekt" is a note Anja entered in the file but it is not a valid feature value.
                unless($value eq '_' || $value eq '' || $value eq 'Imperfekt')
                {
                    push(@flist, "$fnames[$i]=$value");
                }
            }
            my $features = '_';
            if(scalar(@flist) > 0)
            {
                $features = join('|', sort {lc($a) cmp lc($b)} (@flist));
            }
            # One extra column for the copy of the original features.
            my $n = scalar(@fnames)+1;
            # Insert one extra underscore character for the XPOSTAG.
            splice(@af, 4, $n, '_', $features);
        }
        # Check whether all lemmas are filled out.
        if($af[2] eq '_' || $af[2] eq '')
        {
            # Three remaining verbs are known to be lemmaless.
            if($af[1] eq 'wuhotuje')
            {
                $af[2] = 'wuhotować';
            }
            elsif($af[1] eq 'priwatizowali')
            {
                $af[2] = 'priwatizować';
            }
            elsif($af[1] eq 'rozbije')
            {
                $af[2] = 'rozbić';
            }
            $n_empty_lemmas++;
            print STDERR ("Empty lemma on line $i_line; filling out $af[2]\n");
        }
        # Print the annotation to the output, converted back to the CoNLL-U format.
        print(join("\t", @af), "\n");
    }
    # Empty lines between sentences: the CSV file will have many empty cells there, remove them.
    elsif($oline =~ m/^\s*$/)
    {
        if($aline !~ m/^\s*$/)
        {
            print STDERR ("Sentence-level mismatch: '$oline' --> '$aline'\n");
        }
        print("\n");
    }
    # Sentence-level comments with sentence ids.
    else
    {
        # The CSV line will have multiple empty cells at the end. Remove them.
        $aline =~ s/\s+$//s;
        # Sentence ids may differ in the language code. Remove it.
        my $ol1 = $oline;
        my $al1 = $aline;
        $ol1 =~ s:^(\#\s+sent_id\s+.+)/[^/]+$:$1:;
        $al1 =~ s:^(\#\s+sent_id\s+.+)/([a-z]+)$:$1:;
        $languages{$2}++;
        if($ol1 ne $al1)
        {
            print STDERR ("Sentence-level mismatch: '$oline' --> '$aline'\n");
        }
        # Print the line to STDOUT.
        print("$aline\n");
    }
}
close(ORIG);
close(ANNO);
my @languages = sort {$languages{$b} <=> $languages{$a}} (keys(%languages));
print STDERR ("Found the following language codes:\n");
foreach my $language (@languages)
{
    print STDERR ("$language\t$languages{$language}\n");
}
print STDERR ("$n_empty_lemmas nodes have empty lemmas.\n");
