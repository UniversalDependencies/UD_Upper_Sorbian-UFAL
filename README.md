# Summary

A small treebank of Upper Sorbian based mostly on Wikipedia, partly also on other Sorbian websites.


# Introduction

The Upper Sorbian sentences are taken from the W2C corpus (Martin Majliš), which
was further manually filtered, morphologically and syntactically annotated by
Daniel Zeman; lemmatization by Anna Nedoluzhko.

Paragraphs in the W2C corpus were shuffled but since UD v2.17, we restored their original order where possible, and
added document boundaries and ids. Articles from Wikipedia have document ids starting with "wiki-". The remaining
texts come mostly from the web of the Sorbian Institute, some of them also from the websites of Sorbian-speaking
municipalities.


# Changelog

* 2025-11-15 v2.17
  * Deshuffled paragraphs, restored original documents where possible.
  * Removed the sample "train" data, everything is now labeled as "test" (until we have enough data for a proper split).
  * Added ExtPos feature to heads of fixed multiword expressions.
* 2021-05-15 v2.8
  * Fixed: SpaceAfter=No no longer occurs at the end of a paragraph.
* 2018-05-15 v2.4
  * Fixed: `goeswith` no longer used in situations with punctuation or gaps.
* 2018-11-15 v2.3
  * Fixed some UPOS-DEPREL mismatches.
* 2018-04-15 v2.2
  * Repository renamed from UD_Upper_Sorbian to UD_Upper_Sorbian-UFAL.


<pre>
=== Machine-readable metadata (DO NOT REMOVE!) ================================
Data available since: UD v2.1
License: CC BY-SA 4.0
Includes text: yes
Parallel: no
Genre: wiki nonfiction
Lemmas: manual native
UPOS: manual native
XPOS: manual native
Features: manual native
Relations: manual native
Contributors: Zeman, Daniel; Nedoluzhko, Anna
Contributing: here
Contact: zeman@ufal.mff.cuni.cz
===============================================================================
</pre>
