# Upper Sorbian Universal Dependencies treebank

get:
	# Take data from the W2C corpus (web part, shuffled paragraphs).
	# Filter out the noise. Many sentences are Italian, Slovenian, Polish, Latvian etc. but not Sorbian.
	# Tokenize it and convert it to CoNLL-U, storing the surface form using SpaceAfter=No where appropriate.
	zcat /net/data/W2C/W2C_WEB/2011-08/hsb.txt.gz |\
		/net/work/people/zeman/deltacorpus/text_to_conll.pl |\
		/net/work/people/zeman/deltacorpus/filter.pl hsb |\
		filter_hsb_richieste.pl \
		> data/hsb-filtered-spaceafter.conllu
	# Count paragraphs and tokens.
	wc_conll.pl data/hsb-filtered-spaceafter.conllu

install_tagger:
	# Lightweight Upper Sorbian tagger by Daniil Sorokin.
	git clone https://bitbucket.org/magpie/part-of-speech-tagger-for-upper-sorbian.git
	# Download unversioned files, such as the PDF documentation, from https://bitbucket.org/magpie/part-of-speech-tagger-for-upper-sorbian/downloads.

tag:
	# The tagger requires plain text as input.
	# We had to convert it to CoNLL-U because that's what our filtering scripts expect. So let's detokenize it for the tagger again.
	cat data/hsb-filtered-spaceafter.conllu | detok_conllu.pl > data/hsb-filtered-detok.txt
	# The files closedClassWords.txt, dictionary.txt and morphology.txt must be in the current folder.
	# Otherwise we must specify the paths to them using tagger options.
	# We ask for all tags that the tagger finds plausible. They will be ordered from the highest to the lowest probability.
	java -jar TaggerUpperSorbian.jar --allTags data/hsb-filtered-detok.txt data/hsb-filtered-tagged.txt
	# The Stanford tokenizer, built in the tagger, sometimes works differently from ours.
	# We have to synchronize the two tokenizations again, using a few ad-hoc hacks.
	# Running our tokenizer before the tagger might help but it would not solve everything. For instance, the tagger replaces certain characters by something else!
	# Note that the names of the input files are currently hard-wired in the script.
	# The subsequent cleaning moves tagger output to more appropriate columns.
	merge_conllu_tagged.pl data/hsb-filtered-spaceafter.conllu data/hsb-filtered-tagged.txt |\
		clean_up_after_tagger.pl > data/hsb-tagged.conllu

# The text is segmented to paragraphs. We will segment paragraphs to sentences manually,
# to avoid problems with fixing bad segmentation at later stages. We will keep track of
# the original paragraphs using paragraph ids.
paragraph_ids:
	insert_paragraph_ids.pl < data/hsb-tagged.conllu > data/hsb-tagged-pids.conllu

# Now edit the file, insert a blank line between every two sentences within a paragraph, then save it as hsb-manually-segmented.conllu.
# Erase bad sentences that escaped the previous filtering. Then run the following cleanup:
sentence_ids:
	clean_up_after_segmentation.pl < data/hsb-manually-segmented.conllu > data/hsb-segmented.conllu
	# There are many duplicate sentences. (Not naturally occurring duplicates but the same text downloaded multiple times.)
	# Keep only the first occurrence of each sentence.
	remove_duplicate_sentences.pl < data/hsb-segmented.conllu > data/hsb-deduplicated.conllu
	tag_statistics.pl data/hsb-deduplicated.conllu > data/tag_statistics.txt
	wc_conll.pl data/hsb-deduplicated.conllu

# Convert the tags to Universal POS & features (there is now an Interset driver, created with the help of tag_statistics.txt).
# Remove the original tags. There is no extra information in them, and they clutter the file.
# Also remove the alternative tags from the MISC column. Manual checking is necessary in any case, and the alternatives do not help it.
convert_tags:
	convert_tags.pl < data/hsb-deduplicated.conllu > data/hsb-uposf.conllu
	cat data/hsb-uposf.conllu | udapi.pl Read::CoNLLU HSB::FixTags Write::CoNLLU > data/hsb-uposf-autofixed.conllu

# Prepare a CSV file that can be opened in a spreadsheet editor such as LibreOffice Calc and manually annotated.
# First pass:
#MANMORPHIN=data/hsb-uposf-autofixed.conllu
# Second pass:
MANMORPHIN=data/hsb-13-postmorph.conllu
MANMORPHOUT=data/hsb-14-manual-morphology-od-anji.csv
pre_manual_annotation:
	generate_table_for_annotation.pl < $(MANMORPHIN) > data/hsb-manual-morphology.csv

# Open the CSV file in LibreOffice Calc and edit it.
# Refer to the screenshot in jak_spravne_otevrit_csv.jpg for import parameters.
# During annotation, save the file in the LibreOffice native format: data/hsb-manual-morphology.ods
# Do not insert or remove lines or columns. Keep track separately about changes of that nature that have to be done.
# For example, in our case there were 5 omitted sentence breaks, one extra break that should be undone, and 100 sentences in wrong language (Lower Sorbian most of the time).
# We marked the wrong-language sentences by changing the language code in their id. We noted the sentence break errors separately for future processing.
# Refer to the screenshot in jak_spravne_ulozit_csv.jpg for export parameters.
# Sanity check: Make sure that the annotated file has the same number of lines (LibreOffice probably removed the empty line after the last sentence)
# and that all words match those in the input file.
post_manual_annotation:
	sanity_check_after_annotation.pl $(MANMORPHIN) $(MANMORPHOUT) > data/hsb-15-manual-lemmas.conllu

# If there are any pending sentence-break issues, fix them now, before we discard the wrong-language sentences.
# (If we noted the line numbers where sentence breaks are wrong, we want the numbers to be still valid.
# For that reason also, make sure to process the issues bottom-up!)
# Make sure that sentence ids and word ids in the new sentences are manually fixed!
# Save the result as data/hsb-manual-morphology-segmentation-fixed.conllu.
# Then finally filter the sentences where we have verified the language.
filter_language:
	filter_by_language.pl hsb < data/hsb-manual-morphology-segmentation-fixed.conllu > data/hsb-2ndfilter.conllu
	filter_by_language.pl dsb < data/hsb-manual-morphology-segmentation-fixed.conllu > data/dsb-2ndfilter.conllu

# Automatically fix certain POS tags and features and add certain lemmas.
# The remaining lemmas will have to be added in another round of manual annotation.
fix_morphology:
	postmorph.pl < data/hsb-2ndfilter.conllu > data/hsb-postmorph.conllu

post_anja_annotation:
	sanity_check_after_annotation.pl data/hsb-13-postmorph.conllu data/hsb-14-manual-morphology-od-anji.csv > data/hsb-15-manual-lemmas.conllu

# After the second round of manual morphological annotation (lemmatization by Anja) we don't repeat the steps
# filter_language and fix_morphology, thus we end with post_manual_annotation. We now have more than 10 columns
# per line (there are some extra columns for double-checking the annotation). Remove the extra columns and get
# a valid CoNLL-U file. EDIT: This was only needed when the previous step interpreted the columns wrongly!
#trim_columns:
#	trim_extra_columns.pl < data/hsb-15-manual-lemmas.conllu > data/hsb-16-manual-lemmas-10columns.conllu

# Convert CoNLL-U to Treex so that syntax can be annotated in Tred.
# Parse the tree using a delexicalized Czech model; that should save us some manual work.
conllu_to_treex:
	treex -Lhsb \
		Read::CoNLLU from=data/hsb-postmorph.conllu \
		W2A::Delexicalize keep_iset=1 \
		W2A::ParseMalt model=/ha/work/people/zeman/hamledt/parsing/delex/cs-ud12/100000/malt_stacklazy_delex.mco cpos_attribute=tag pos_attribute=tag feat_attribute=iset deprel_attribute=deprel is_member_within_afun=0 is_shared_modifier_within_afun=0 is_coord_conjunction_within_afun=0 \
		Util::Eval anode='my $$w=$$.wild; $$.set_form($$w->{form}); $$.set_lemma($$w->{lemma}); %{$$w}=()' \
		Write::Treex to=data/hsb-17-for-tred-parser.treex

# Convert the syntactically annotated Treex file back to CoNLL-U.
treex_to_conllu:
	treex -Lhsb \
		Read::Treex from=data/hsb-17-for-tred-parser.treex \
		Util::Eval anode='$$.set_conll_pos("_"); $$.set_deprel("expl:pv") if($$.deprel() eq "expl")' \
		Write::CoNLLU print_zone_id=0 to=data/hsb-18-manual-syntax.conllu

# Merge lemmatization from Anja with syntax from Dan.
merge_lemmas_syntax:
	merge_lemmas_syntax.pl data/hsb-15-manual-lemmas.conllu data/hsb-18-manual-syntax.conllu > data/hsb-19-merged.conllu 2> data/merge.log

# Convert the data to Universal Dependencies v2: this part is done in the HamleDT pipeline.

# Guess paragraph boundaries from sentence ids.
guess_paragraphs:
	/net/work/people/zeman/hamledt/normalize/conllu_docpar_from_sentid.pl < data/hsb-20-udv2.conllu > data/hsb-21-ud-newpar.conllu

stats:
	cat data/hsb-postmorph.conllu | perl ../tools/conllu-stats.pl > stats.xml
