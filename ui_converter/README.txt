This directory contains ui<->xml converter.

Code was originally written by alpaca (Stefan Reutter).

What you see in this directory is based on alpaca's
version 1.1 from 25th August 2010, with various patches,
mostly support for older versions of ui layout files
(for ETW).

Right now three versions of ui layout files are supported:
* Version032 - a few ETW files
* Version033 - most of ETW files
* Version039 - most of NTW files

A handful of files have older versions but they're not supported yet.

At the moment each version has separate Python script,
it would be obviously a lot more convenient to merge them in the future.

=== Usage ===

Depending on version of ui layout file you want to convert do one of the following:

$ python3.1 convert_ui_v39.py -u uifile uifile.xml
$ python3.1 convert_ui_v39.py -x uifile.xml uifile

$ python3.1 convert_ui_v33.py -u uifile uifile.xml
$ python3.1 convert_ui_v33.py -x uifile.xml uifile

$ python3.1 convert_ui_v32.py -u uifile uifile.xml
$ python3.1 convert_ui_v32.py -x uifile.xml uifile

