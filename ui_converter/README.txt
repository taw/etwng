This directory contains ui<->xml converter.

Most of the code was originally written by alpaca (Stefan Reutter).

What you see in this directory is based on alpaca's version 1.1
from 25th August 2010, with various patches by taw (Tomasz Wegrzanowski),
mostly support for older versions of ui layout files (for ETW).

You need Python 3.x for this converter.
It will not work with Python 2.x

== Versions of UI layout format ==

Right now three versions of ui layout files are supported:
* Version032 - a few ETW and NTW files
* Version033 - most of ETW files, a few NTW files
* Version039 - most of NTW files

Between ETW and NTW and ignoring duplicates between games,
number of UI layout files by format version are:

  1 Version025
  1 Version027
  2 Version028
  3 Version029
  1 Version030
  1 Version031
 12 Version032
112 Version033
133 Version039

In other words, it's not a huge loss that versions older than 032 are not supported.
If you really need to open one of the pre-Version032 files, contact taw.

=== Usage ===

There's now a single script which handles Version032, Version033, and Version039.
Depending on version of ui layout file you want to convert do one of the following:

$ python3.1 convert_ui.py -u uifile uifile.xml
$ python3.1 convert_ui.py -x uifile.xml uifile

== S2TW Support ==

I added support for some S2TW files.

For now only Version043 is supported, that's 3 files total, but it's important first step.
