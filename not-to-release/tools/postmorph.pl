#!/usr/bin/env perl
# Kontroluje hornolužickou morfologii a vyplňuje lemmata.
# Copyright © 2016 Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL

use utf8;
use open ':utf8';
binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

my %lemmas =
(
    # Comparative adverbs.
    'bóle'     => 'mnoho',
    'dale'     => 'daloko',
    'lěpje'    => 'derje',
    'mjenje'   => 'mało',
    'mjeńše'   => 'mało', # To je překlep, správně je "mjenje". A pozor, tohle je správně u ADJ, kde by ale lemma bylo "mały".
    'pozdźišo' => 'pozdźe',
    'rědšo'    => 'rědko',
    'wjace'    => 'wjele',
    'zašo'     => 'bórze',
    # Superlative adverbs.
    'najbliže'  => 'blisko',
    'najbóle'   => 'mnoho',
    'najprjedy' => 'bórze',
    'najskerje' => 'skerje', # nejspíše
    'najwjace'  => 'wjele',
);

while(<>)
{
    unless(m/^\#/ || m/^\s*$/)
    {
        my @f = split(/\t/, $_);
        my $form = lc($f[1]);
        my $lemma = $f[2];
        my $upos = $f[3];
        my $feat = $f[5];
        if($upos eq 'ADP')
        {
            # Rys AdpType=Prep je u slovanských jazyků zbytečný. Záložky se téměř nevyskytují.
            $feat = join('|', grep {!m/AdpType/} (split(/\|/, $feat)));
            $feat = '_' if(!defined($feat) || $feat eq '');
            $lemma = get_adp_lemma($form);
            #$h{"$form $lemma $upos $feat"}++;
            # Uložit změněné lemma a rysy.
            $f[2] = $lemma;
            $f[5] = $feat;
        }
        elsif($upos eq 'CONJ')
        {
            $lemma = $form;
            # Rozdělit spojky na souřadící (CONJ) a podřadící (SCONJ).
            # Souřadící spojky:
            # a = a; abo = nebo; ale = ale; ani = ani; (et = et); pak = pak (nebo je to ADV? Ale na rozdíl od cs to možná nejde použít místo "potom".); tola = ale, avšak, přece
            # Podřadící spojky:
            # chibazo = ledaže; dokelž = jelikož; doniž = až než; hačrunjež = ačkoli; hdyž = když; jako = jako; jeli = jestliže; kaž = jako(ž); li = li; zo = že
            # Obojetné spojky:
            # hač = "až" (CONJ), ale taky "zda" (SCONJ) nebo srovnávací "než" (SCONJ)
            # Tázací/vztažné příslovce, chybně označené jako spojka:
            # kak = jak
            if($form eq 'kak')
            {
                $upos = 'ADV';
                $feat = 'PronType=Int,Rel';
            }
            elsif($form =~ m/^(chibazo|dokelž|doniž|hačrunjež|hdyž|jako|jeli|kaž|li|zo|hač)$/)
            {
                $upos = 'SCONJ';
            }
            #$h{"$form $lemma $upos $feat"}++;
            # Uložit změněné lemma, značku a rysy.
            $f[2] = $lemma;
            $f[3] = $upos;
            $f[5] = $feat;
        }
        elsif($upos eq 'PART')
        {
            # da = tedy, pak, což, cožpak; hdy da = kdy, kdypak, kdyže; kak da = jak, jakpak
            # hakle = až, teprve až, až když; podle Františka Martínka a Katji Brankačkec je to ADV; v cs UD je "teprve" ADV, "až" může být CONJ, SCONJ, ale taky PART; já bych nechal PART, má to omezující význam podobně jako české "jen"
            # hišće = ještě, nadto; v češtině je "ještě" ADV
            # hižo = už, již; v češtině je obojí ADV
            # jenož = jen, jenom; v češtině je obojí PART
            # nic = ne (záporná částice: "Pětr je pilny, Jana nic" = "Petr je pilný, Jana ne")
            # wšak = však, vždyť; podle Františka a Katji je to PART; v českých UD je obojí CONJ
            if($form =~ m/^(hišće|hižo)$/)
            {
                $upos = 'ADV';
            }
            elsif($form eq 'wšak')
            {
                $upos = 'CONJ';
            }
            elsif($form eq 'nic')
            {
                $feat = 'Negative=Neg';
            }
            $lemma = $form;
            # Uložit změněné lemma, značku a rysy.
            $f[2] = $lemma;
            $f[3] = $upos;
            $f[5] = $feat;
        }
        # Čísla a interpunkce mají jako lemma samy sebe.
        elsif($upos =~ m/^(PUNCT|SYM|X)$/ || $form =~ m/^\d+$/)
        {
            $f[2] = $form;
        }
        # Zkontrolovat, zda mi někde nezůstalo AdpType (pokud jsme předložku přeznačili jako něco jiného).
        if($feat =~ m/AdpType/)
        {
            if($form eq 'wotpowědnje')
            {
                $f[2] = $lemma = 'wotpowědnje';
                $f[3] = $upos = 'ADP';
                $f[5] = $feat = '_';
            }
            else
            {
                # U ostatních nechat značku, ale jen odstranit dotyčný rys.
                $feat = join('|', grep {!m/AdpType/} (split(/\|/, $feat)));
                $feat = '_' if(!defined($feat) || $feat eq '');
                $f[5] = $feat;
            }
        }
        # Příslovce se dělí na stupňovatelná a zájmenná (deiktická).
        # Nejméně jeden výskyt "wjele" je omylem označkován jako "ADJ".
        if($upos eq 'ADV' || $form eq 'wjele')
        {
            if($form eq 'kak')
            {
                # Jednou jsme měli Int,Rel a jednou jen Int. Sjednotit.
                $feat = 'PronType=Int,Rel';
            }
            # Chybějící PronType:
            # dotal (doteď, Dem), druhdy (někdy, občas, Ind), nětko (nyní, teď, Dem), potajkim (tak, tedy, Dem),
            # potom (potom, Dem), pódla (přitom, Dem), tak (tak, Dem), tohodla (proto, Dem), tróšku (trochu, Ind),
            # tuchwilu (v tu chvíli, Dem), tuž (tedy, Dem), tójšto (dost, Ind), zdobom (ve stejnou chvíli, Dem)
            elsif($form =~ m/^(dotal|nětko|potajkim|potom|pódla|tak|tohodla|tuchwilu|tuž|zdobom)$/)
            {
                $feat = 'PronType=Dem';
            }
            elsif($form =~ m/^(druhdy)$/)
            {
                $feat = 'PronType=Ind';
            }
            elsif($form =~ m/^(tróšku|tójšto)$/)
            {
                $feat = 'NumType=Card|PronType=Ind';
            }
            elsif($form =~ m/^(wjele)$/)
            {
                $upos = 'ADV';
                $feat = 'Degree=Pos|NumType=Card|PronType=Ind';
            }
            # "mjeńše" je překlep, má být "mjenje". Takhle by to bylo přídavné jméno.
            elsif($form =~ m/^(mjenje|mjeńše|wjace)$/)
            {
                $feat = 'Degree=Cmp|NumType=Card|PronType=Ind';
            }
            # VerbType=Mod should not be used with adverbs.
            elsif($form =~ m/^(móžno)$/)
            {
                $feat = 'AdvType=Mod';
                $lemma = $form;
            }
            # Nestupňují se, ale neoznačil bych je za zájmenná:
            # dźensa (dnes), hišće (ještě), hižo (už), hromadu, hromadźe (spolu, dohromady),
            # lědma, lědom, lědy (sotva, ledva), mjeztym (zatím), nachwilu (chvíli),
            # naposledk(u) (naposledy), napřikład (například), nimale (skoro, málem, bezmála, téměř), poněčim (trochu), popołdnju (odpoledne),
            # přeco (přece), předewšěm (především), tež (také, též), wróćo (zpět), wězo (ovšem),
            # zaso (zase), zdźěla (zčásti), zhromadnje (dohromady), znowa (znova), znutřka (zevnitř), zwjetša (většinou), zwonka (zvenku)
            if($form =~ m/^(dźensa|hišće|hižo|hromadu|hromadźe|lědma|lědom|lědy|mjeztym|nachwilu|naposledk|naposledku|napřikład|nimale|poněčim|popołdnju|přeco|předewšěm|tež|wróćo|wězo|zaso|zdźěla|zhromadnje|znowa|znutřka|zwjetša|zwonka)$/)
            {
                $feat = '_';
                $lemma = $form;
            }
            # Chybějící druhý stupeň: bóle (více), dale (dále), pozdźišo (později), rědšo (řidčeji; je tam chybně Pos), zašo (dříve)
            elsif($form =~ m/^(bóle|dale|pozdźišo|rědšo|zašo)$/)
            {
                $feat = 'Degree=Cmp';
                # Nemůžeme nastavit lemma, protože nevíme, jak zní první stupeň (totéž pro další příslovce, u kterých už druhý stupeň byl vyznačen).
            }
            # Chybějící třetí stupeň: najprjedy (nejdříve)
            elsif($form =~ m/^(najprjedy)$/)
            {
                $feat = 'Degree=Sup';
                # Nemůžeme nastavit lemma, protože nevíme, jak zní první stupeň (totéž pro další příslovce, u kterých už třetí stupeň byl vyznačen).
            }
            elsif($feat eq '_')
            {
                $feat = 'Degree=Pos';
            }
            if($lemma eq '_' && $feat !~ m/Abbr/)
            {
                if($feat !~ m/Degree=(Cmp|Sup)/)
                {
                    $lemma = $form;
                }
                elsif(exists($lemmas{$form}))
                {
                    $lemma = $lemmas{$form};
                }
            }
            # The abbreviation "atd" (etc.) abbreviates a multi-word expression and has itself as lemma (same in Czech).
            elsif($form eq 'atd')
            {
                $lemma = 'atd';
            }
            $h{"$form $lemma $upos $feat"}++;
            # Uložit změněné lemma, značku a rysy.
            $f[2] = $lemma;
            $f[3] = $upos;
            $f[5] = $feat;
        }
        # Jestliže má sloveso pád, pak jsme při úpravě příčestí zapomněli změnit značku na ADJ.
        if($upos eq 'VERB' && $feat =~ m/Case=/)
        {
            $f[3] = $upos = 'ADJ';
        }
        # Jestliže má podstatné jméno stupeň, pak jsme zapomněli změnit značku na ADJ.
        if($upos eq 'NOUN' && $feat =~ m/Degree=/)
        {
            $f[3] = $upos = 'ADJ';
        }
        # Jestliže někde zůstal rod "Fem,Masc", je to špatně.
        if($feat =~ m/Gender=Fem,Masc/)
        {
            # Convert the features to a hash.
            my %fhash = fstring2hash($feat);
            if($form =~ m/^(sobudźěłaćerjo)$/) # sobudźěłaćer
            {
                # Masc Anim
                $fhash{Gender} = 'Masc';
                $fhash{Animacy} = 'Anim';
            }
            elsif($form =~ m/^(porjadow)$/) # porjad
            {
                # Masc Inan
                $fhash{Gender} = 'Masc';
                $fhash{Animacy} = 'Inan';
            }
            elsif($form =~ m/^(podklasow|masy|rěče)$/) # podklasa, masa, rěč
            {
                # Fem
                $fhash{Gender} = 'Fem';
                delete($fhash{Animacy});
            }
            elsif($form =~ m/^(wikach)$/) # wiki = trh(y)
            {
                # Ptan
                $fhash{Number} = 'Ptan';
                delete($fhash{Gender});
                delete($fhash{Animacy});
            }
            # Convert the hash back to a feature string.
            $f[5] = $feat = fhash2string(%fhash);
        }
        # Jestliže má podstatné jméno PronType, pak jsme zapomněli změnit značku na PRON (u zájmena "wono").
        if($upos eq 'NOUN' && $feat =~ m/PronType=/)
        {
            $f[3] = $upos = 'PRON';
        }
        # Jestliže má přídavné jméno PronType, pak jsme zapomněli změnit značku na DET nebo ADV.
        if($upos eq 'ADJ' && $feat =~ m/PronType=/)
        {
            if($form =~ m/^někot/) # někotři, někotrych
            {
                $f[3] = $upos = 'DET';
            }
            elsif($form eq 'wjele') # wjele
            {
                $f[3] = $upos = 'ADV';
                $f[2] = $lemma = 'wjele';
            }
        }
        # Jestliže má přídavné jméno Person, pak jsme zapomněli změnit značku na VERB (u "móže").
        if($upos eq 'ADJ' && $feat =~ m/Person=/)
        {
            $f[3] = $upos = 'VERB';
        }
        # Jestliže má podstatné nebo přídavné jméno způsob a čas, pak jsme je zapomněli vyhodit, když jsme rušili značku VERB.
        if($upos =~ m/^(NOUN|ADJ)$/ && $feat =~ m/Mood=/)
        {
            my %fhash = fstring2hash($feat);
            delete($fhash{VerbForm});
            delete($fhash{Mood});
            delete($fhash{Tense});
            $f[5] = $feat = fhash2string(%fhash);
        }
        if($upos =~ m/^(NOUN)$/ && $feat =~ m/(Tense|VerbForm)=/)
        {
            if($form eq 'eksistowali')
            {
                $f[3] = $upos = 'VERB';
            }
            elsif($form eq 'rozdźělene')
            {
                $f[3] = $upos = 'ADJ';
            }
            else # chloroplasty, bencylisochinolinalkaloidy
            {
                my %fhash = fstring2hash($feat);
                delete($fhash{VerbForm});
                delete($fhash{Voice});
                delete($fhash{Tense});
                $f[5] = $feat = fhash2string(%fhash);
            }
        }
        # Doplnit polaritu u sloves, přídavných jmen a příslovcí.
        if($upos =~ m/^(VERB|ADJ|ADV)$/ && $form =~ m/^nje/)
        {
            # Negative=Neg
            my %fhash = fstring2hash($feat);
            $fhash{Negative} = 'Neg';
            $f[5] = $feat = fhash2string(%fhash);
            # If they already have lemma, make sure that it is the positive form.
            if($lemma =~ s/^nje//)
            {
                $f[2] = $lemma;
            }
        }
        # Mood=ind je překlep, opravit.
        if($feat =~ s/Mood=ind/Mood=Ind/)
        {
            $f[5] = $feat;
        }
        # Imperativ s časem je chyba. Pravděpodobně jsem se uklepl a měl to být indikativ.
        if($feat =~ s/Mood=Imp(.*Tense)/Mood=Ind$1/)
        {
            # V jednom případě je ovšem chyba větší, měl to být přechodník.
            if($form eq 'dajo')
            {
                $feat = 'Tense=Pres|VerbForm=Trans';
            }
            $f[5] = $feat;
        }
        # Jestliže neznáme značku (X, tj. cizí slovo nebo neslovo), neměli bychom znát ani žádné rysy s výjimkou Abbr.
        if($upos eq 'X' && $feat =~ m/=/)
        {
            $feat = $feat =~ m/Abbr=Yes/ ? 'Abbr=Yes' : '_';
            $f[5] = $feat;
        }
        # Číslovka "jedyn" (jeden) se skloňuje jako přídavné jméno. Rozlišuje rod, pád, případně i číslo (cs: jedny bačkory; existuje něco takového v hsb?).
        if($form =~ m/^jed(yn|na|ne|neho|neje|nemu|nej|nu|nym|ny)$/)
        {
            $f[2] = $lemma = 'jedyn';
            $f[3] = $upos = 'NUM';
        }
        # Číslovka "dwaj" (dva) a "wobaj" (oba) rovněž rozlišuje rod a pád. Číslo je inherentně dvojné.
        elsif($form =~ m/^(dw|wob)(aj|ě|eju|ěmaj)$/)
        {
            $f[2] = $lemma = $1.'aj';
            $f[3] = $upos = 'NUM';
        }
        # Římské číslice mají za lemma samy sebe, ale velkými písmeny.
        elsif($upos eq 'NUM' && $form =~ m/^[ivxlcdm]+$/)
        {
            $f[2] = $lemma = uc($form);
        }
        # Vyšší číslovky, které se zatím vyskytly v datech:
        # tři, traje, štyri, štyrjoch, pjeć, šěsć, sydom, dźewjeć, dźesać, dwanaće, štyrnaće, pjatnaće, třiceći
        # Neurčité a zvláštní: mnoho, wjele, poł, połdra, sta, tysac
        elsif($upos eq 'NUM')
        {
            # Vypadá to, že srbské číslovky nerozlišují pád, až na pár výjimek, které jsem zahlédl a které odporují učebnici.
            # Číslo je taky asi zbytečné. Je jasné, že počítané věci jsou v plurálu, ale celá fráze může pro sloveso fungovat jako singulár.
            # U rodu a životnosti si nejsem jistý. Podle učebnice se používají jiné tvary pro racionální substantiva než (default) pro neracionální.
            my %fhash = fstring2hash($feat);
            delete($fhash{Case});
            delete($fhash{Number});
            if($form =~ m/^(štwórć|poł|połdra|tři|štyri|pjeć|šěsć|sydom|wosom|dźewjeć|dźesać|jědnaće|dwanaće|třinaće|štyrnaće|pjatnaće|šěsnaće|sydomnaće|wosomnaće|dźewjatnaće|dwaceći|třiceći|štyrceći|pjećdźesat|šěsćdźesat|sydomdźesat|wosomdźesat|dźewjećdźesat|st[oa]|tysac)$/)
            {
                $f[2] = $lemma = $1;
                if($form eq 'sta') { $f[2] = $lemma = 'sto'; }
            }
            elsif($form eq 'traje')
            {
                # To vypadá jako chyba. Jako kdyby to autor celé udělal v duálu (!): "traje dalšej měsacaj".
                $f[2] = $lemma = 'tři';
            }
            elsif($form eq 'štyrjoch')
            {
                # Výjimka z pravidla, že číslovky se neskloňují podle pádu.
                $f[2] = $lemma = 'štyri';
                $fhash{Case} = 'Gen';
            }
            elsif($form eq 'mnoho')
            {
                # Unlike "wjele" and other indefinite numeral-adverbs, "mnoho" is never used as ADV, only as NUM.
                $f[2] = $lemma = 'mnoho';
            }
            elsif($form eq 'wjele')
            {
                # Other occurrences are already tagged as ADV with NumType=Card.
                $f[2] = $lemma = 'wjele';
                $f[3] = $upos = 'ADV';
                $fhash{Degree} = 'Pos';
            }
            $f[5] = $feat = fhash2string(%fhash);
        }
        if($upos eq 'PRON')
        {
            my %fhash = fstring2hash($feat);
            # Osobní zájmeno v 1. osobě: ja, mój, my, mje, mnje, mi, mni, mnu, naju, namaj, nas, nam, nami (v korpusu se zatím vyskytlo pouze "nam").
            if($form =~ m/^(ja|mój|my|mje|mnje|mi|mni|mnu|naju|namaj|nas|nam|nami)$/)
            {
                $f[2] = $lemma = 'ja';
            }
            # Osobní zájmeno ve 2. osobě: ty, wój, wy, tebe, će, tebi, ći, tobu, waju, wamaj, was, wam, wami (v korpusu zatím jen "ty" a jednou mu chybí pád).
            elsif($form =~ m/^(ty|wój|wy|tebe|će|tebi|ći|tobu|waju|wamaj|was|wam|wami)$/)
            {
                $f[2] = $lemma = 'ty';
                unless(defined($fhash{Case}))
                {
                    $fhash{Case} = 'Nom';
                }
            }
            # Osobní zájmeno ve 3. osobě v nominativu.
            elsif($form =~ m/^(wón|wona|wono|wone|wonaj|wonej|woni)$/)
            {
                $f[2] = $lemma = 'wón';
                # Jednou tam máme "wono" použité jako akuzativ, ale to je zřejmě chyba.
                $fhash{Case} = 'Nom';
                # Zájmena nerozlišují životnost v singuláru ("wón" je obojí).
                # V duálu a plurálu životnost hraje roli (mužský osobní vs. všechno ostatní).
                if($fhash{Number} eq 'Sing' || $fhash{Gender} ne 'Masc')
                {
                    delete($fhash{Animacy});
                }
            }
            # Nenominativní tvary zájmen 3. osoby, které se nepletou s přivlastňovacími zájmeny.
            elsif($form =~ m/^(njeho|jemu|njemu|nim|jón|njón|njeje|jej|ju|nju|njej|jo|njo|je|nje|njeju|jimaj|nimaj|njich|jim|nich|nimi)$/)
            {
                $f[2] = $lemma = 'wón';
            }
            # Zvratné zájmeno.
            elsif($form =~ m/^(so|sebje|sej|sebi|sobu)$/)
            {
                $f[2] = $lemma = 'so';
                # Zvratná zájmena nerozlišují číslo.
                delete($fhash{Number});
                if($form eq 'so' && !defined($fhash{Case}))
                {
                    $fhash{Case} = 'Acc';
                }
            }
            # Ukazovací zájmeno; pouze střední rod singuláru; ostatní jsou DET; i tohle je ambiguitní s DET.
            elsif($form =~ m/^(t|to|toho|tomu|tym)$/)
            {
                $f[2] = $lemma = 'to';
                $fhash{Gender} = 'Neut';
                delete($fhash{Animacy});
                $fhash{Number} = 'Sing';
            }
            # Tázací a vztažné zájmeno "štó" (kdo) a "što" (co).
            elsif($form =~ m/^(štó|koho|komu|kim)$/)
            {
                $f[2] = $lemma = 'štó';
            }
            elsif($form =~ m/^(ně|ni)?(što|čeho|čemu|čo|čim)(ž)?$/)
            {
                $f[2] = $lemma = $1.'što'.$3;
            }
            $f[5] = $feat = fhash2string(%fhash);
        }
        if($upos =~ m/^(PRON|DET)$/)
        {
            my %fhash = fstring2hash($feat);
            # Přivlastňovací zájmena, která se nepletou s osobními.
            if($form =~ m/^m(ój|oja|oje|ojeho|ojemu|ojim|ojeje|ojej|oju|ojeju|ojimaj|oji|ojich|ojimi)$/)
            {
                $f[2] = $lemma = 'mój';
                $f[3] = $upos = 'DET';
                $fhash{Poss} = 'Yes';
                $fhash{'Number[psor]'} = 'Sing';
            }
            elsif($form =~ m/^tw(ój|oja|oje|ojeho|ojemu|ojim|ojeje|ojej|oju|ojeju|ojimaj|oji|ojich|ojimi)$/)
            {
                $f[2] = $lemma = 'twój';
                $f[3] = $upos = 'DET';
                $fhash{Poss} = 'Yes';
                $fhash{'Number[psor]'} = 'Sing';
            }
            elsif($form =~ m/^sw(ój|oja|oje|ojeho|ojemu|ojim|ojeje|ojej|oju|ojeju|ojimaj|oji|ojich|ojimi)$/)
            {
                $f[2] = $lemma = 'swój';
                $f[3] = $upos = 'DET';
                $fhash{Poss} = 'Yes';
            }
            elsif($form =~ m/^naš(a|e|eho|emu|im|eje|ej|u|eju|imaj|i|ich|imi)?$/ || $form eq 'n')
            {
                $f[2] = $lemma = 'naš';
                $f[3] = $upos = 'DET';
                $fhash{Poss} = 'Yes';
                $fhash{'Number[psor]'} = 'Plur';
            }
            elsif($form =~ m/^waš(a|e|eho|emu|im|eje|ej|u|eju|imaj|i|ich|imi)?$/)
            {
                $f[2] = $lemma = 'waš';
                $f[3] = $upos = 'DET';
                $fhash{Poss} = 'Yes';
                $fhash{'Number[psor]'} = 'Plur';
            }
            # Přivlastňovací zájmena ve třetí osobě nebo genitiv osobních zájmen.
            # Pouze "jeho" se ve dvou případech a "jeju" v jednom objevilo jako osobní zájmeno, jinak jsou všechno přivlastňovací.
            # Jen tyto případy mají nastavený pád.
            elsif($form eq 'jeho' && $fhash{Case} =~ m/^(Nom)?$/)
            {
                $f[2] = $lemma = $form;
                $fhash{Poss} = 'Yes';
                # Rod vlastněného podstatného jména je neznámý.
                delete($fhash{Gender});
                delete($fhash{Animacy});
                # Číslo vlastněného podstatného jména je neznámé.
                delete($fhash{Number});
                delete($fhash{Case});
                $fhash{'Number[psor]'} = 'Sing';
                $fhash{'Gender[psor]'} = 'Masc,Neut';
                $f[3] = $upos = 'DET';
            }
            elsif($form eq 'jeje' && $fhash{Case} =~ m/^(Nom)?$/)
            {
                $f[2] = $lemma = $form;
                $fhash{Poss} = 'Yes';
                # Rod vlastněného podstatného jména je neznámý.
                delete($fhash{Gender});
                delete($fhash{Animacy});
                # Číslo vlastněného podstatného jména je neznámé.
                delete($fhash{Number});
                delete($fhash{Case});
                $fhash{'Number[psor]'} = 'Sing';
                $fhash{'Gender[psor]'} = 'Fem';
                $f[3] = $upos = 'DET';
            }
            # A teď ty výjimečné případy, kdy jeho/jeje má nastavený pád a není to přivlastňovací zájmeno.
            elsif($form =~ m/^(jeho|jeje)$/)
            {
                $f[2] = $lemma = 'wón';
            }
            elsif($form eq 'jeju')
            {
                $f[2] = $lemma = $form;
                $fhash{Poss} = 'Yes';
                # Rod vlastněného podstatného jména je neznámý.
                delete($fhash{Gender});
                delete($fhash{Animacy});
                # Číslo vlastněného podstatného jména je neznámé.
                delete($fhash{Number});
                delete($fhash{Case});
                $fhash{'Number[psor]'} = 'Dual';
                $f[3] = $upos = 'DET';
            }
            elsif($form eq 'jich')
            {
                $f[2] = $lemma = $form;
                $fhash{Poss} = 'Yes';
                # Rod vlastněného podstatného jména je neznámý.
                delete($fhash{Gender});
                delete($fhash{Animacy});
                # Číslo vlastněného podstatného jména je neznámé.
                delete($fhash{Number});
                delete($fhash{Case});
                $fhash{'Number[psor]'} = 'Plur';
                $f[3] = $upos = 'DET';
            }
            # Ukazovací zájmeno (s výjimkou "to", které už jsme vyřešili výše).
            elsif(!($upos eq 'PRON' && $fhash{Number} eq 'Sing' && $fhash{Gender} eq 'Neut') &&
                  $form =~ m/^(tón|t(a|e|[eo]ho|omu|ym|eje|ej|u|eju|ymaj|ych|ymi))$/)
            {
                $f[2] = $lemma = 'tón';
                $f[3] = $upos = 'DET';
            }
            elsif($form =~ m/^(tutón|tut(a|e|[eo]ho|omu|ym|eje|ej|u|eju|ymaj|y|ych|ymi))$/)
            {
                $f[2] = $lemma = 'tutón';
                $f[3] = $upos = 'DET';
            }
            elsif($form eq 'tudyšej')
            {
                $f[2] = $lemma = 'tudyši';
                $f[3] = $upos = 'DET';
            }
            # "Totální" neurčité zájmeno.
            elsif($form =~ m/^kóžd(y|a|e|eho|emu|ym|eje|ej|u|ych|ymi)(žkuli)?$/)
            {
                $f[2] = $lemma = 'kóždy'.$2;
                $f[3] = $upos = 'DET';
            }
            elsif($form =~ m/^wš(ě|ěch|ěm|eho|emu)$/)
            {
                $f[2] = $lemma = 'wšě';
                $f[3] = $upos = 'DET';
            }
            elsif($form =~ m/^wšitk(e|im|ich)$/)
            {
                $f[2] = $lemma = 'wšitki';
                $f[3] = $upos = 'DET';
            }
            elsif($form =~ m/^wšelak(e|im|ich)$/)
            {
                $f[2] = $lemma = 'wšelaki';
                $f[3] = $upos = 'DET';
            }
            # Vztažné zájmeno (neměli bychom z něj udělat determinátor? Skloňuje se jako přídavné jméno.)
            elsif($form =~ m/^(ně)?kot(ry|ra|re|reho|remu|rym|reje|rej|ři|rych|rymi)(ž)?$/)
            {
                my $z = $3;
                $f[2] = $lemma = $1.'kotry'.$z;
                $f[3] = $upos = 'DET';
            }
            elsif($form =~ m/^([kt]|něk)ajk([iae]|eho|ej|ich)$/)
            {
                $f[2] = $lemma = $1.'ajki';
                $f[3] = $upos = 'DET';
            }
            elsif($form =~ m/^(kiž|wšitko)$/)
            {
                $f[2] = $lemma = $form;
            }
            # Záporné zájmeno.
            elsif($form =~ m/^(žadyn|žan(a|e|eho|emu|im|eje|ej|u|eju|imaj|i|ich|imi))$/)
            {
                $f[2] = $lemma = 'žadyn';
                $f[3] = $upos = 'DET';
            }
            # tutón; "t" v "t.mj." ("tak mjenowany") a v "t.r." (asi "to rěka" = "to znamená"); tych
            $f[5] = $feat = fhash2string(%fhash);
        }
        # "něhdźe" is ADV (not PRON) and has no Case or Number
        # We fix it here. Even if PRON has been changed to ADV earlier manually, we want to check the features.
        if($form eq 'něhdźe')
        {
            $f[2] = $lemma = $form;
            $f[3] = $upos = 'ADV';
            $f[5] = $feat = 'PronType=Ind';
        }
        # Fix known ADJ-NOUN errors.
        if($upos eq 'NOUN' && $form =~ m/^anti(komunisti|semiti|słowjan)ska$/)
        {
            $f[3] = $upos = 'ADJ';
            $f[5] = $feat = 'Case=Nom|Degree=Pos|Gender=Fem|Number=Sing';
        }
        elsif($upos eq 'ADJ' && $form =~ m/^(eksonymy|płoda|tafli|zjawnosći)$/)
        {
            $f[3] = $upos = 'NOUN';
        }
        # For open classes, identify words that are already in the base form.
        if($upos eq 'VERB')
        {
            if($form =~ m/^(njej?)?(być|sym|sy|je|smój|st[ae]j|smy|sće|su|bud(u|źeš|źe?|źe?moj|źe?t[ae]j|źe?my|źe?će|u)|b[ěuy]ch|bě(še)?|b[uy]|b[ěuy]chmoj|b[ěuy]št[ae]j|b[ěuy]chmy|b[ěuy]šće|b[ěuy]chu|by(ł(a|o|oj)?|li))$/)
            {
                $f[2] = $lemma = 'być';
            }
            elsif($feat =~ m/VerbForm=Inf/)
            {
                $lemma = $form;
                $lemma =~ s/^nje//;
                $f[2] = $lemma;
            }
        }
        elsif($upos eq 'NOUN')
        {
            ($lemma, $feat) = get_noun_morphology($form, $feat);
            $f[2] = $lemma;
            $f[5] = $feat;
        }
        elsif($upos eq 'PROPN')
        {
            # Lemma of a proper noun must start with a capital letter.
            # That's why we supply the original $f[1] instead of lowercased $form.
            ($lemma, $feat) = get_propn_morphology($f[1], $feat);
            $f[2] = $lemma;
            $f[5] = $feat;
        }
        elsif($upos eq 'ADJ')
        {
            ($lemma, $feat) = get_adj_morphology($form, $feat);
            $f[2] = $lemma;
            $f[5] = $feat;
        }
        $_ = join("\t", @f);
    }
    print;
}
#print_statistics();



#------------------------------------------------------------------------------
# Vypíše statistiky z globálního hashe.
#------------------------------------------------------------------------------
sub print_statistics
{
    foreach my $k (sort(keys(%h)))
    {
        print("$k\t$h{$k}\n");
    }
}



#------------------------------------------------------------------------------
# Převede řetězec rysů na hash.
#------------------------------------------------------------------------------
sub fstring2hash
{
    my $feat = shift;
    # Convert the features to a hash.
    my %fhash;
    foreach my $pair (split(/\|/, $feat))
    {
        next if($pair eq '_');
        my ($f, $v) = split(/=/, $pair);
        $fhash{$f} = $v;
    }
    return %fhash;
}



#------------------------------------------------------------------------------
# Převede hash rysů na řetězec.
#------------------------------------------------------------------------------
sub fhash2string
{
    my %fhash = @_;
    my $feat = join('|', sort {lc($a) cmp lc($b)} (map {"$_=$fhash{$_}"} (keys(%fhash))));
    $feat = '_' if(!defined($feat) || $feat eq '');
    return $feat;
}



#------------------------------------------------------------------------------
# Podle tvaru podstatného jména zjistí jeho lemma a případně upraví rysy.
#------------------------------------------------------------------------------
sub get_noun_morphology
{
    my $form = shift; # předpokládáme, že případná velká písmena byla převedena na malá
    my $feat = shift; # předpokládáme, že tato funkce se nevolá u zkratek (Abbr=Yes)
    my $lemma = '_';
    my %fhash = fstring2hash($feat);
    if($feat !~ m/(Abbr)/)
    {
        if($form =~ m/^(administrator|awtor|kejžor|nomad|referent|susod|wjelbłud|wosoł)(a|ej|o|u|aj|ow|omaj|ojo|y|źa|am|ach|ami)?$/)
        {
            $lemma = $1;
            $fhash{Gender} = 'Masc';
            $fhash{Animacy} = $lemma =~ m/^(wjelbłud|wosoł)$/ ? 'Nhum' : 'Anim';
        }
        elsif($form =~ m/^(.+is)ća$/)
        {
            $lemma = $1.'t';
            $fhash{Gender} = 'Masc';
            $fhash{Animacy} = 'Anim';
        }
        elsif($form =~ m/^(fachowc|jednobańkowc|měchawc|překupc|wuměłc|zajimc)(a|ej|o|u|aj|ow|omaj|y|am|ach|ami)?$/)
        {
            $lemma = $1;
            $fhash{Gender} = 'Masc';
            $fhash{Animacy} = $lemma =~ m/^(jednobańkowc|měchawc)$/ ? 'Nhum' : 'Anim';
        }
        elsif($form =~ m/^(boh|bóh|monarch|wjerch|žiwoch)(a|ej|o|u|aj|ow|omaj|i|ojo|am|ach|ami)?$/)
        {
            $lemma = $1;
            $fhash{Gender} = 'Masc';
            $fhash{Animacy} = $lemma =~ m/^(žiwoch)$/ ? 'Nhum' : 'Anim';
        }
        elsif($form =~ m/^(cyca|linguisti|měšni|njewólni|přećiwni|rěčespytni|rěčni|rjapni|rje|wotrjadni|zastupni)(k|ka|kej|ko|ku|kom|kaj|kow|komaj|cy|kam|kach|kami)$/)
        {
            $lemma = $1.'k';
            $fhash{Gender} = 'Masc';
            $fhash{Animacy} = $lemma =~ m/^(cycak|rjapnik)$/ ? 'Nhum' : 'Anim';
        }
        elsif($form =~ m/^(knježićel|kral)(a|ej|o|om|ow|omaj|o?jo|am|ach|emi)?$/ ||
              $form =~ m/^(gramatikar|historikar|moler|pisar|přełožowar|ratar|sobudźěłaćer|spisowaćel|wobydler|wopytowar|wužiwar|zastupjer)(ja|jej|jo|ju|jom|jow|jomaj|je|jam|jach|jemi)?$/)
        {
            $lemma = $1;
            $fhash{Gender} = 'Masc';
            $fhash{Animacy} = 'Anim';
        }
        elsif($form =~ m/^(kóń|kon(ja|jej|jo|ju|jom|jow|jomaj|je|jam|jach|jemi))$/)
        {
            $lemma = 'kóń';
            $fhash{Gender} = 'Masc';
            $fhash{Animacy} = 'Nhum';
        }
        elsif($form =~ m/^(čłowjek(a|ej|o|u|om|aj|ow|omaj)|ludź(o|i|om|och|imi))$/)
        {
            $lemma = 'čłowjek';
            $fhash{Gender} = 'Masc';
            $fhash{Animacy} = 'Anim';
        }
        # krótkopowědančko je Neut, ale jednou se vyskytlo i jako Masc Anim, což je určitě špatně
        # Podle slovníku je "symbioza" rodu ženského, ale autoři textu to viděli jinak, použili lokativ "w symbiozu".
        # "elekron" je překlep, má být "elektron".
        # "matabolizm" je překlep, má být "metabolizm".
        elsif($form =~ m/^(adwerb|archiw|atom|bazar|bencylisochinolinalkaloid|centrum|cokor|dom|dualizm|eksemplar|eksonym|elekron|elektron|eponym|eudikotyledon|fenomen|hamor|hrib|izotop|januar|jězor|kmjen|matabolizm|metabolizm|mikroorganizm|milion|monokotyledon|monsun|morf|motiw|neolignan|neolitikum|niwow|ocean|organ|organizm|paragraf|piktogram|płun|pokiw|poměr|por|postup|powětr|preteritum|pronomen|region|row|rozměr|rozpor|rum|scanner|sejm|serwer|sewjer|směr|stereotyp|substantiw|synchronizm|system|škrob|takson|terpen|tetraedr|typ|werb|wideoklip|widejoklip|wliw|woznam|wustup|wutwor|zaměr)(a|ej|o|je|u|om|aj|ow|omaj|y|am|ach|ami)?$/ ||
              $form =~ m/^(dokład|fenylpropanoid|hybrid|juhowuchod|juhozapad|karotinoid|likwid|lud|narod|nawod|pad|płod|pochad|porjad|přikład|pyrenoid|sewjerowuchod|sewjerozapad|spad|wid|wobchod|wobwod|wotrjad|wuchod|zapad)(a|ej|o|źe|om|aj|ow|omaj|y|am|ach|ami)?$/ ||
              $form =~ m/^(čas|časopis|dialekt|dom|dopokaz|epos|genus|golf|kołmaz|kónc|lětopis|lěttysac|měrc|měsac|numerus|papyrus|počas|proces|rytmus|spis|symbioz|symjeńc|winowc|wobraz|wokrjes|wotkaz|wotrys|wukaz|zapis)(a|ej|o|u|om|aj|ow|omaj|y|am|ach|ami)?$/ ||
              $form =~ m/^(běh|bok|cyłk|dawk|diftong|dypk|dźenik|juh|kašćik|kislik|kónčk|kopěrak|krok|kruh|kružk|krytosymjenjak|kusk|lětnik|lětstotk|ličak|měsačk|moch|nadawk|nastawk|njedostatk|pazork|pěsk|pěstk|pisak|pismik|płódnik|podawk|pomjatk|poćah|powjerch|pož[ćč]onk|prućik|přednošk|přełožk|přibrjoh|přinošk|přitok|reich|rozmach|róžk|schodźenk|słownik|smažnik|spočatk|srědk|srjedźowěk|starowěk|sćěh|tydźenik|wikisłownik|wobhladowak|wobłuk|wobrazk|wobsah|wobstatk|wodźik|wokołk|wokruh|wotběh|wupisk|wuskutk|wuslědk|wuspěch|wutk|zak|zawiječk|zběrnik|zběžk|zbytk|zwisk|zwjazk|zwuk)(a|ej|o|u|om|aj|ow|omaj|i|am|ach|ami)?$/ ||
              $form =~ m/^(artikl|cil|cyhel|dešć|detail|dźěl|chlorophyll|jubilej|junij|kanal|kapitl|kraj|kubl|mej|mikrotubulij|model|muzej|nazal|nuhel|pakić|piksel|połwokal|protokol|puć|symbol|templ|teritorij|titl|ćišć|wokal|wolij|wukraj|zemjedźěl|zmysl)(a|ej|o|u|om|aj|ow|omaj|e|am|ach|emi)?$/)
        {
            $lemma = $1;
            $fhash{Gender} = 'Masc';
            $fhash{Animacy} = 'Inan';
        }
        elsif($form =~ m/^(wóz|woz(a|ej|o|u|om|aj|ow|omaj|y|am|ach|ami))$/)
        {
            $lemma = 'wóz';
            $fhash{Gender} = 'Masc';
            $fhash{Animacy} = 'Inan';
        }
        # Podle učebnice by lokativ slova "brjóh" ("břeh") měl být "při brjóhu", ale v textu jsem objevil "při brjóze".
        elsif($form =~ m/^(brj[óo])(h|ha|hej|ho|hu|ze|hom|haj|how|homaj|hi|ham|hach|hami)$/)
        {
            $lemma = 'brjóh';
            $fhash{Gender} = 'Masc';
            $fhash{Animacy} = 'Inan';
        }
        elsif($form =~ m/^(sto)(ł|ła|łej|ło|le|łom|łaj|łow|łomaj|ły|łam|łach|łami)$/)
        {
            $lemma = $1.'ł';
            $fhash{Gender} = 'Masc';
            $fhash{Animacy} = 'Inan';
        }
        # "instutut" a "insitut" jsou překlepy, má být "institut".
        elsif($form =~ m/^(ablaw|aspek|awgus|cikura|cita|cytoskele|dokumen|embryofy|eukaryo|forma|gametofy|holocaus|hydra|chloroplas|idioblas|insitu|institu|instutu|interne|konflik|konsonan|kontak|kontinen|my|namje|objek|orbi|palas|parazi|pergamen|pěs|pigmen|plane|podkas|produk|projek|pru|přewró|sanskri|silika|sporofy|sta|subkontinen|swě|teks|tribu)(t|ta|tej|to|će|tom|taj|tow|tomaj|ty|tam|tach|tami)$/)
        {
            $lemma = $1.'t';
            $fhash{Gender} = 'Masc';
            $fhash{Animacy} = 'Inan';
        }
        elsif($form =~ m/^(cent|cylind|decemb|kalend|kilomet|oktob|paramet|pikomet|silwest|septemb)(er|ra|rej|ro|rje|ru|rom|raj|row|romaj|ry|ram|rach|rami)$/)
        {
            $lemma = $1.'er';
            $fhash{Gender} = 'Masc';
            $fhash{Animacy} = 'Inan';
        }
        elsif($form =~ m/^(kamje|korje|stopje|tydźe|zako)(ń|nja|njej|nju|njom|njej|njow|njomaj|nje|njam|njach|njemi)$/)
        {
            $lemma = $1.'ń';
            $fhash{Gender} = 'Masc';
            $fhash{Animacy} = 'Inan';
        }
        elsif($form =~ m/^(dźeń|dn(ja|jej|ju|jom|aj|jow|jomaj|y|jam|jach|jemi))$/)
        {
            $lemma = 'dźeń';
            $fhash{Gender} = 'Masc';
            $fhash{Animacy} = 'Inan';
        }
        elsif($form =~ m/^(rjad(a|ej|u|om|aj|ow|omaj|y|am|ach|ami)?|rjedźe)$/)
        {
            $lemma = 'rjad';
            $fhash{Gender} = 'Masc';
            $fhash{Animacy} = 'Inan';
        }
        elsif($form =~ m/^(hody|hód|hodom|hodźoch)$/)
        {
            $lemma = 'hody'; # Vánoce
            $fhash{Number} = 'Ptan';
            $fhash{Gender} = 'Masc';
            $fhash{Animacy} = 'Inan';
        }
        elsif($form =~ m/^(adres|baz|celuloz|diferenc|faz|hranic|inteligenc|klas|konferenc|kopańc|kopic|licenc|lijeńc|mas|podklas|połojc|praks|prowinc|referenc|směrnic|stolic|substanc|šans|škleńc|šmic|wučbnic|wustajeńc)(a|y|e|u|ow|omaj|am|ach|ami)$/ ||
              $form =~ m/^(akkadšćin|aramejšćin|architektur|atmosfer|barb|bělkowin|čěšćin|diktatur|disciplin|dob|družbin|družin|figurin|finšćin|form|francošćin|germanšćin|gmejn|grup|hindišćin|hładźin|hor|horin|hosćin|hudźb|chinšćin|italšćin|japanšćin|jendźelšćin|karawan|klim|kónčin|krajin|kultur|kup|lěpšin|lisćin|literatur|łušćin|madźaršćin|maćizn|membran|měr|modern|mongolšćin|němčin|nižin|nop|podswójb|pólšćin|połkup|posłužb|potrjeb|přičin|rostlin|runin|ryb|serwjernogermanšćin|skupin|słowakšćin|słužb|stawizn|stron|struktur|sćěn|sumerišćin|swójb|šlešćin|španšćin|štwórćin|šwedšćin|tem|temperatur|turkowšćin|twor|wjazb|wójn|wosob|wosobin|wupraw|zelenin|změn|žratw)(a|y|je|u|ow|omaj|am|ach|ami)$/ ||
              $form =~ m/^(bjesad|jahod|miliard|period|pód|rěčewěd|rjad|sad|srjed|škod|wod|zasad)(a|y|źe|u|ow|omaj|am|ach|ami)$/ ||
              $form =~ m/^(smoł)(a|y|u|ow|omaj|am|ach|ami)$/ || # nechytí dativ "smole"
              $form =~ m/^(alg|dróh|knih|předłoh|smuh)(a|i|u|ow|omaj|am|ach|ami)$/ || # nechytí dativ "předłoze"
              $form =~ m/^(epoch)(a|i|u|ow|omaj|am|ach|ami)$/ || # nechytí dativ "epoše"
              $form =~ m/^(akademij|anteridij|archegonij|bakterij|bibliografij|biografij|biologij|dataj|definicij|deklinacij|disertacij|dispozicij|dokumentacij|dynastij|encyklopedij|erozij|federacij|fleksij|funkcij|generacij|geografij|geometrij|informacij|institucij|interpretacij|kooperacij|koordinacij|kopij|kutikul|linij|materialij|medij|naturalij|njedźel|opcij|organizacij|ortografij|póndźel|pozicij|proklamacij|proporcij|publikacij|reakcij|recensij|recitacij|reprezentacij|reprodukcij|ról|studij|šul|tafl|technologij|tekstilij|teorij|teritorij|tradicij|transpiracij|unij|wersij|wikipedij)(a|e|i|u|ow|omaj|am|ach|emi)$/)
        {
            $lemma = $1.'a';
            $fhash{Gender} = 'Fem';
            delete($fhash{Animacy});
        }
        elsif($form =~ m/^(bań|bibliote|botani|brěč|brošur|drohoćin|eklipti|gramati|hór|chroni|jednot|kamuš|kap|kerami|kladisti|leksi|namakan|poraž|proty|referent|rě|rěč|republi|romanti|ru|sorabisti|sćěw|systemati|techni|temati|wjes|wotnož|zběr|złóž)(ka|ki|ce|ku|kow|komaj|kam|kach|kami)$/)
        {
            $lemma = $1.'ka';
            $fhash{Gender} = 'Fem';
            delete($fhash{Animacy});
        }
        elsif($form =~ m/^(deba|del|hódno|kar|mjezo|pla|sobo|ćopło|uniwersi|wěsto|wjesto)(ta|ty|će|tu|tow|tomaj|tam|tach|tami)$/)
        {
            $lemma = $1.'ta';
            $fhash{Gender} = 'Fem';
            delete($fhash{Animacy});
        }
        elsif($form =~ m/^(atmosfer|čitarn|kniharn|knihown|korčm|krom|morchw|rostlinarn|zem)(ja|je|i|ju|jow|jomaj|jam|jach|jemi)$/)
        {
            $lemma = $1.'ja';
            $fhash{Gender} = 'Fem';
            delete($fhash{Animacy});
        }
        elsif($form =~ m/^(moc|móc|pomoc|wěc)(y|u|ow|omaj|am|ach|ami)?$/)
        {
            $lemma = $1;
            $fhash{Gender} = 'Fem';
            delete($fhash{Animacy});
        }
        elsif($form =~ m/^(činitosć|disponujomnosć|dokonjanosć|dołhosć|formalnosć|kajkosć|kić|krutosć|ležownosć|lódź|městnosć|móžnosć|mróčel|napjatosć|njewotwisnosć|płaćiwosć|podobnosć|podrobnosć|prarěč|přestrjeń|přitomnosć|rěč|rumnosć|sel|smjerć|swojoraznosć|syć|šěrokosć|tačel|towaršnosć|wažnosć|wědomosć|wosebitosć|wulkosć|wysokosć|wyšnosć|zamołwitosć|zańdźenosć|zašłosć|zjawnosć)(e|i|u|ow|omaj|am|ach|emi)?$/)
        {
            $lemma = $1;
            $fhash{Gender} = 'Fem';
            delete($fhash{Animacy});
        }
        elsif($form =~ m/^(bas)(eń|nje|ni|nju|njow|njomaj|njam|njach|njemi)$/)
        {
            $lemma = $1.'eń';
            $fhash{Gender} = 'Fem';
            delete($fhash{Animacy});
        }
        elsif($form =~ m/^(čłowjestw|hospodarstw|knihiwjedstw|knjejstw|knježerstw|kralestw|łopjen|ministerstw|mišterstw|mjen|mnóstw|mócnarstw|nakładnistw|namrěwstw|napism|pism|prapism|praw|přećelstw|přiwuznistw|rozswětlerstw|słow|staćanstw|win|wjednistw|wobsydstw|wobydlerstw|zarjadnistw|zjednoćenstw)(o|a|u|je|om|ow|omaj|am|ach|ami)$/ ||
              $form =~ m/^(čisł|dźěł|prawidł|sydł|žiwidł|žórł)(o|a|u|om|ow|omaj|am|ach|ami)$/ || # nechytí lokativ "dźěle"
              $form =~ m/^(łopješk|wójsk|znamješk)(o|a|u|om|ow|omaj|am|ach|ami)$/ || # nechytí duál "jabłuce"
              $form =~ m/^(słónc|ćěles)(o|a|u|om|y|ow|omaj|am|ach|ami)$/ ||
              $form =~ m/^(bydlišć|čol|nalěć|pol|prawidl|ćěl|srjedźišć)(o|a|u|om|i|ow|omaj|am|ach|ami)$/)
        {
            $lemma = $1.'o';
            $fhash{Gender} = 'Neut';
            delete($fhash{Animacy});
        }
        elsif($form =~ m/^(lě|měs)(to|ta|tu|će|tom|t|tow|tomaj|tam|tach|tami)$/)
        {
            $lemma = $1.'to';
            $fhash{Gender} = 'Neut';
            delete($fhash{Animacy});
        }
        elsif($form =~ m/^(mor|symjen)(jo|ja|ju|jom|i|jow|jomaj|jam|jach|jemi)$/)
        {
            $lemma = $1.'jo';
            $fhash{Gender} = 'Neut';
            delete($fhash{Animacy});
        }
        elsif($form =~ m/^(čitan|dalokowikowan|dobywan|dótknjen|dźělen|hiban|hladan|chlěbpječen|kćen|ličen|měnjen|nahrawan|nanjesen|napominan|naprašowan|narunan|nastajen|nastupan|našmórnjenjen|pomjenowan|postajen|powodźen|prašen|promjenjen|předstajen|překročen|přeměnjen|přepasen|přesunjen|připućowan|pućowan|rozsudźen|slědźen|stupjen|twarjen|tworjen|ćahan|wikowan|wobkedźbowan|wobmjezowan|wočakowan|wopisan|wotwalen|wozjewjen|wozrodźen|wujasnjen|wuměnjen|wupožčen|wurjekowan|wusyłan|wužiwan|zarjadowan|znamjen|zranjen|zrěčen|zwjazan|žadan)(je|ja|ju|jom|i|jow|jomaj|jam|jach|jemi)$/)
        {
            $lemma = $1.'je';
            $fhash{Gender} = 'Neut';
            delete($fhash{Animacy});
        }
        elsif($form =~ m/^(nastać|předewzać|spóznać|sydlišć|wuwić|wuwzać|zaćmić|zapřijeć|zarjadnišć|zdać)(e|a|u|om|i|ow|omaj|am|ach|emi)$/)
        {
            $lemma = $1.'e';
            $fhash{Gender} = 'Neut';
            delete($fhash{Animacy});
        }
        # Pomnožná podstatná jména nemají rod (resp. skloňování "durje" = "dveře" má asi nejblíže k rodu ženskému ("rjadownja"), ale je to těžké poznat a genitiv "duri" je stejně výjimka).
        elsif($form =~ m/^(dur)(je|jow|i|jam|jach|jemi)$/)
        {
            $lemma = 'durje';
            delete($fhash{Gender});
            delete($fhash{Animacy});
            $fhash{Number} = 'Ptan';
        }
        if($lemma eq '_' || $lemma eq '')
        {
            if($feat =~ m/Case=Nom.*Number=(Sing|Ptan)/)
            {
                $lemma = $form;
            }
            elsif($feat =~ m/Animacy=Inan.*Case=Acc.*Gender=Masc.*Number=Sing/ ||
                  $feat =~ m/Case=Acc.*Gender=Neut.*Number=Sing/ ||
                  $feat =~ m/Case=Acc.*Number=Ptan/)
            {
                $lemma = $form;
            }
        }
    }
    else # zkratky podstatných jmen
    {
        if($form eq 'l')
        {
            $lemma = 'lětoličba'; # letopočet
            $fhash{Gender} = 'Fem';
            delete($fhash{Animacy});
        }
        elsif($form eq 'mio')
        {
            $lemma = 'milion'; # milión
            $fhash{Gender} = 'Masc';
            $fhash{Animacy} = 'Inan';
        }
        elsif($form eq 'př')
        {
            $lemma = 'přikład'; # příklad
            $fhash{Gender} = 'Masc';
            $fhash{Animacy} = 'Inan';
        }
    }
    $feat = fhash2string(%fhash);
    return ($lemma, $feat);
}



#------------------------------------------------------------------------------
# Podle tvaru podstatného jména zjistí jeho lemma a případně upraví rysy.
#------------------------------------------------------------------------------
sub get_propn_morphology
{
    my $form = shift; # předpokládáme, že případná velká písmena byla převedena na malá
    my $feat = shift; # předpokládáme, že tato funkce se nevolá u zkratek (Abbr=Yes)
    my $lemma = '_';
    my %fhash = fstring2hash($feat);
    if($feat !~ m/(Abbr)/)
    {
        # Masculine animates: personal names, members of nations and ethnic groups, inhabitants of a territory.
        if($form =~ m/^(Adolf|Ammiṣaduq|Arjan|Bolesław|Cygan|dan|ditan|Fredegar|German|Grimm|Grjek|iddin|Jacob|Heinrich|Hitler|Klemen|Krystus|Med|Rom|Romjan|Sargon|Seleukid|Shay|Słowjan|Wood|Žid)(a|je|om|ojo|ow)?$/ ||
           $form =~ m/^(Balt|Hetit|Kelt)(ojo|ow|am|ach|ami)?$/ ||
           $form =~ m/^(Assurbanipal|Pregelj)(a)?$/ ||
           $form =~ m/^(Assyričen|Babylonjan|Babylonjen|Serb|.+čan)(jo|ja|ow|am|ach|ami)?$/)
        {
            $lemma = $1;
        }
        # Masculine names ending in -a inflect similarly to feminines.
        elsif($form =~ m/^(Samsuilun)(a|y)$/)
        {
            $lemma = $1.'a';
        }
        elsif($form =~ m/^(Andre)(ho)?$/)
        {
            $lemma = $1;
        }
        elsif($form =~ m/^(Chrobry)(m)?$/)
        {
            $lemma = $1;
        }
        # Names of countries and regions, adjective-like type "Mezopotamiska".
        elsif($form =~ m/sk(a|eje|ej|u)$/)
        {
            $lemma = $form;
            $lemma =~ s/sk(a|eje|ej|u)$/ska/;
        }
        # Masculine inanimates
        elsif($form =~ m/^(Andrapradeš|ARPANET|Azerbajdźan|Bobr|Dagestan|Habur|Iran|Kazachstan|Leiden|Pradeš|Turkmenistan|Ur|Zab)(a|om)?$/ ||
              $form =~ m/^(Akkad)(a|om)?$/ ||
              $form =~ m/^(Akropolis|Drjowk|Choćebuz|Irak|Pacifik|Petersburg|Rapenburg|Taurus|Tigris|Zagros)(a|u|om)?$/ ||
              $form =~ m/^(Himalaj)(e)?$/ ||
              $form =~ m/^(Israel)(u)?$/
              )
        {
            $lemma = $1;
            $fhash{Gender} = 'Masc';
            $fhash{Animacy} = 'Inan';
        }
        elsif($form =~ m/^(Eufra|Interne|Murejbe)(t|ta|će|tom)?$/)
        {
            $lemma = $1.'t';
        }
        elsif($form =~ m/^(Babylon|Berlin|Budyšin|Dekkan|Main|Mohan)(a|je|om)?$/)
        {
            $lemma = $1;
        }
        # Feminine
        elsif($form =~ m/^(Florid|Gow|Keral|Kwis|Łužic|Maharaštr|Maćic|Palestin|Solaw|Wódr)(a|y|u|omaj)$/ ||
              $form =~ m/^(Azij|Biblij|Ginej|Oceanij|Tansanij|Wikipedij)(a|e|u|i|ow)$/ ||
              $form =~ m/^(Europ)(a|y|je)$/)
        {
            $lemma = $1.'a';
        }
        elsif($form =~ m/^(Afri|Ameri)(ka|ki|ce)$/)
        {
            $lemma = $1.'ka';
        }
        elsif($form =~ m/^(Zem)(ja|i)$/)
        {
            $lemma = $1.'ja';
        }
        elsif($form =~ m/^(Wenus)(y)?$/)
        {
            $lemma = $1;
        }
        # Neuter
        elsif($form =~ m/^(Jerich|Łobj)(o|a|om)$/)
        {
            $lemma = $1.'o';
        }
        # Pluralia tantum
        elsif($form =~ m/^(Wik)(i|ow|ach)$/)
        {
            $lemma = $1.'i';
        }
        elsif($form =~ m/^(Alp|Drježdźan)(y|ow|ach)$/)
        {
            $lemma = $1.'y';
        }
        # Indeclinable names that have gender and/or animacy and/or number (for agreement) but not case.
        elsif($form =~ m/^(Adl|Commons|Ešarrje|Foundation|Geuzen|Honolulu|Kindle|Muršili|Nadu|Pisces|Sucre|Surbi|Tlustulimu|Wikimedia|Zamośće)$/)
        {
            $lemma = $1;
        }
        # Proper names without features are indeclinable.
        # That should also apply to all foreign, non-Slavic names, including German.
        # Some of them currently have non-empty features in the data, so we must list them as exceptions.
        elsif($feat eq '_' ||
              $form =~ m/^(Stätten|Stationen|religiösen|Wirkens|Gasche)$/)
        {
            $lemma = $form;
            %fhash = ();
        }
        if($lemma eq '_' || $lemma eq '')
        {
            if($feat =~ m/Case=Nom.*Number=(Sing|Ptan)/)
            {
                $lemma = $form;
            }
            elsif($feat =~ m/Animacy=Inan.*Case=Acc.*Gender=Masc.*Number=Sing/ ||
                  $feat =~ m/Case=Acc.*Gender=Neut.*Number=Sing/ ||
                  $feat =~ m/Case=Acc.*Number=Ptan/)
            {
                $lemma = $form;
            }
        }
    }
    else # zkratky vlastních jmen
    {
        if($form =~ m/^(C|CET|GNU|H|KPD|NDR|OZN)$/)
        {
            $lemma = $form;
        }
    }
    $feat = fhash2string(%fhash);
    return ($lemma, $feat);
}



#------------------------------------------------------------------------------
# Podle tvaru přídavného jména zjistí jeho lemma a případně upraví rysy.
#------------------------------------------------------------------------------
sub get_adj_morphology
{
    my $form = shift; # předpokládáme, že případná velká písmena byla převedena na malá
    my $feat = shift; # předpokládáme, že tato funkce se nevolá u zkratek (Abbr=Yes)
    my $lemma = '_';
    my %fhash = fstring2hash($feat);
    if($feat !~ m/(Abbr)/)
    {
        # Prefixy složených adjektiv před spojovníkem, tj. pouze kmen a spojovací hláska "o". Příklad: "syrisko" v "syrisko-arabska".
        if($feat !~ m/Case/ && $form =~ m/[bcčdhjklłmnprstwz]o$/)
        {
            $lemma = $form;
            # Výjimky:
            # awstro-aziski ... awstro, ne awstry
            # tibeto-burmaski ... tibetski, ne tibety
            # zapado a sewjernogermanšćina ... tady ani není spojovník a přídavné jméno; buď můžeme dát "zapadny", nebo nechat "zapado" po vzoru "awstro"
            unless($lemma =~ m/^(awstro|zapado)$/)
            {
                $lemma =~ s/tibeto$/tibetski/;
                $lemma =~ s/([bcdłmnprstwz])o$/${1}y/;
                $lemma =~ s/([čhklšć])o$/${1}i/;
                $lemma =~ s/([bmnprswz])jo$/${1}i/;
                die if($lemma =~ m/o$/); # sanity check
            }
            # Protože máme pouze kmen slova, nevíme rod, číslo, pád ani stupeň. To vše nese až poslední část složeniny.
            %fhash = ('Hyph' => 'Yes');
        }
        # U prvního stupně a u přídavných jmen, která se nestupňují, můžeme použít nominativ nebo neživotný akuzativ.
        elsif($feat !~ m/Degree=(Cmp|Sup)/)
        {
            if($feat =~ m/Case=Nom.*Gender=Masc.*Number=Sing/ ||
               $feat =~ m/Animacy=Inan.*Case=Acc.*Gender=Masc.*Number=Sing/)
            {
                $lemma = $form;
            }
            elsif($form =~ s/([čhkć])(i|a|e|eho|emu|im|eje|ej|u|aj|eju|imaj|ich|imi)$/${1}i/)
            {
                $lemma = $form;
            }
            # Koncovka "-o" se vyskytla jen jednou (kromě složenin řešených výše), a to v následující větě (buď je to chyba, nebo neosobní tvar jako v ukrajinštině):
            # Wjele starobabylonskich sydlišćow bu rozpušćeno.
            # Proč povolujeme i "0": "1990ych lět".
            elsif($form =~ s/([bcłmnrtwz0])(y|a|[eo]|eho|emu|ym|eje|ej|u|aj|eju|ymaj|ych|ymi)$/${1}y/)
            {
                $lemma = $form;
            }
            # Pořád nemám jasno, jak je to s případným změkčováním u tvrdých zdrojů.
            # Zdá se, že přinejmenším nominativ plurálu u mužských osobních (racionálních) tvarů dochází ke změně "y" na "i" a případně též ke změkčení předcházející souhlásky.
            # "stari gramatikarjo" = "staří gramatici" (zatímco singulár by asi byl "stary gramatikar" = "starý gramatik")
            # Koncovka "-i" se u tvrdého vzoru vyskytuje v množném čísle osobního mužského rodu.
            # Nemůžeme ji ale rozpoznávat po souhláskách, které se objevují i v měkkém vzoru (změkčované pomocí "j", viz níže), zejména ne po "-n-".
            elsif($form =~ s/([bcłmrtz0])i$/${1}y/)
            {
                $lemma = $form;
            }
            elsif($form =~ s/([nw])(i|ja|je|jeho|jemu|im|jeje|jej|ju|jaj|jeju|imaj|ich|imi)$/${1}i/)
            {
                $lemma = $form;
            }
            # Pravopisné chyby.
            elsif($form eq 'běle')
            {
                $lemma = 'běły';
            }
            elsif($form eq 'ratarkse')
            {
                $lemma = 'ratarski'; # zemědělský
            }
            if($lemma =~ s/^nje//)
            {
                $fhash{Negative} = 'Neg';
            }
        }
        # Zbytek se zabývá druhými a třetími stupni, ale i adjektivy, která mají na konci kmene souhlásku "š" a přitom jsou v prvním stupni.
        if($form =~ m/^(naj)?wjetš(i|a|e|eho|emu|im|eje|ej|u|aj|eju|imaj|ich|imi)$/)
        {
            $lemma = 'wulki';
            $fhash{Degree} = $form =~ m/^naj/ ? 'Sup' : 'Cmp';
        }
        elsif($form =~ m/^(naj)?mjeńš(i|a|e|eho|emu|im|eje|ej|u|aj|eju|imaj|ich|imi)$/)
        {
            $lemma = 'mały';
            $fhash{Degree} = $form =~ m/^naj/ ? 'Sup' : 'Cmp';
        }
        elsif($form =~ m/^(naj)?(čas|hus)ćiš(i|a|e|eho|emu|im|eje|ej|u|aj|eju|imaj|ich|imi)$/)
        {
            $lemma = $2.'ty';
            $fhash{Degree} = $form =~ m/^naj/ ? 'Sup' : 'Cmp';
        }
        elsif($form =~ m/^(naj)?dlěš(i|a|e|eho|emu|im|eje|ej|u|aj|eju|imaj|ich|imi)$/)
        {
            $lemma = 'dołhi';
            $fhash{Degree} = $form =~ m/^naj/ ? 'Sup' : 'Cmp';
        }
        elsif($form =~ m/^(naj)?młódš(i|a|e|eho|emu|im|eje|ej|u|aj|eju|imaj|ich|imi)$/)
        {
            $lemma = 'młody';
            $fhash{Degree} = $form =~ m/^naj/ ? 'Sup' : 'Cmp';
        }
        elsif($form =~ m/^(naj)?pozdźiš(i|a|e|eho|emu|im|eje|ej|u|aj|eju|imaj|ich|imi)$/)
        {
            $lemma = 'pózdni';
            $fhash{Degree} = $form =~ m/^naj/ ? 'Sup' : 'Cmp';
        }
        elsif($form =~ m/^(naj)?rjeńš(i|a|e|eho|emu|im|eje|ej|u|aj|eju|imaj|ich|imi)$/)
        {
            $lemma = 'rjany';
            $fhash{Degree} = $form =~ m/^naj/ ? 'Sup' : 'Cmp';
        }
        elsif($form =~ m/^(naj)?starš(i|a|e|eho|emu|im|eje|ej|u|aj|eju|imaj|ich|imi)$/)
        {
            $lemma = 'stary';
            $fhash{Degree} = $form =~ m/^naj/ ? 'Sup' : 'Cmp';
        }
        elsif($form =~ m/^(naj)?ćopliš(i|a|e|eho|emu|im|eje|ej|u|aj|eju|imaj|ich|imi)$/)
        {
            $lemma = 'ćopły';
            $fhash{Degree} = $form =~ m/^naj/ ? 'Sup' : 'Cmp';
        }
        elsif($form =~ m/^(naj)?wyš(i|a|e|eho|emu|im|eje|ej|u|aj|eju|imaj|ich|imi)$/)
        {
            $lemma = 'wysoki';
            $fhash{Degree} = $form =~ m/^naj/ ? 'Sup' : 'Cmp';
        }
        elsif($form =~ m/^(naj)?(efektiw|jas|kompleks|nuz|rozdźěl|waž|wobšěr|wuznam|zaž)niš(i|a|e|eho|emu|im|eje|ej|u|aj|eju|imaj|ich|imi)$/)
        {
            $lemma = $2.'ny';
            $fhash{Degree} = $form =~ m/^naj/ ? 'Sup' : 'Cmp';
        }
        # Překlep.
        elsif($form eq 'abstrakniše')
        {
            $lemma = 'abstraktny';
            $fhash{Degree} = 'Cmp';
        }
        # "dalši" má tvar 2. stupně (jako od "daloki"), ale asi to spíše vzniklo analogií a odvozením od příslovce "dale".
        # Vztah k "daloki" je sémanticky problematický a 3. stupeň (*najdalši) nejde utvořit.
        # V češtině je "další" samostatné lemma v 1. stupni.
        elsif($form =~ m/^(dalš|dźensniš|hinaš|něhdyš|nětčiš|tamniš|tehdyš)(i|a|e|eho|emu|im|eje|ej|u|aj|eju|imaj|ich|imi)$/)
        {
            $lemma = $1.'i';
            $fhash{Degree} = 'Pos';
        }
        # "bywši" je zpřídavnělé příčestí minulé činné a jako takovému mu neoznačujeme stupeň.
        elsif($form eq 'bywša')
        {
            $lemma = 'bywši';
            delete($fhash{Degree});
        }
    }
    else # zkratky přídavných jmen
    {
        # z. t. = zapisane towarstwo (eingetragener Verein; právní forma)
        # t. mj. = tak mjenowany (takzvaný, tzv.)
        # jendź. = jendźelski (anglický)
        # a. d. = a dalši/druzi? (Adl a. d. 2005 = Adl et al. 2005)
        if($form eq 'z')
        {
            $lemma = 'zapisany';
        }
        elsif($form eq 'mj')
        {
            $lemma = 'mjenowany';
        }
        elsif($form eq 'jendź')
        {
            $lemma = 'jendźelski';
        }
        elsif($form eq 'd')
        {
            $lemma = 'd';
        }
    }
    # Životnost by měla být vyznačena pouze u mužského rodu.
    # V jednotném čísle hraje roli pouze v akuzativu (stareho nana; stareho lwa; stary dub).
    # V dvojném a množném čísle hraje roli v nominativu (stari nanojo; stare lwy; stare duby) a v akuzativu (starych nanow; stare lwy; stare duby).
    if($fhash{Gender} ne 'Masc' ||
       $fhash{Number} eq 'Sing' && $fhash{Case} ne 'Acc' ||
       $fhash{Number} =~ m/^(Dual|Plur)$/ && $fhash{Case} !~ m/^(Nom|Acc)$/)
    {
        delete($fhash{Animacy});
    }
    # Rod v množném čísle hraje roli pouze v nominativu (stari nanojo; stare ženy; stare města) a v akuzativu (starych nanow; stare ženy; stare města).
    # Totéž ve dvojném čísle: nominativ staraj nanaj, akuzativ stareju nanow, vs. neracionální starej žonje, starymaj žonje.
    # Tvary ostatních pádů jsou shodné.
    ###!!! Máme tedy rod v těchto případech také odstranit? Opatrně. V češtině ho tam také máme, přestože dochází k podobným nejednoznačnostem (Gen, Dat, Loc a Ins plurálu jsou shodné pro všechny rody).
    $feat = fhash2string(%fhash);
    return ($lemma, $feat);
}



#------------------------------------------------------------------------------
# Podle tvaru předložky zjistí její lemma.
# Nalezeno 36 různých předložek. Mezi nimi to vypadá na následující páry:
# k - ke
# mjez - mjezy
# n - na (zkratka)
# př - před (zkratka)
# w - we
# z - ze
# Nejčastější předložky jsou w, na, wot.
# Mají mít zkratky jako lemma sebe sama, nebo nezkrácené lemma?
# V češtině je to alespoň u zkratek předložek celá nezkrácená předložka.
#------------------------------------------------------------------------------
sub get_adp_lemma
{
    my $form = shift; # předpokládáme, že případná velká písmena byla převedena na malá
    my $lemma = $form;
    $lemma = 'k' if($form eq 'ke');
    $lemma = 'mjez' if($form eq 'mjezy');
    $lemma = 'na' if($form eq 'n');
    $lemma = 'před' if($form eq 'př');
    $lemma = 'w' if($form eq 'we');
    $lemma = 'z' if($form eq 'ze');
    return $lemma;
}
