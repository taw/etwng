Converter for Total War UI files to and from XML.

It requires Python 3.

## Usage

    $ python3 convert_ui.py -u uifile uifile.xml
    $ python3 convert_ui.py -x uifile.xml uifile

## Versions of UI layout format

UI files in ETW, NTW, and S2TW have different versions from `Version025` to `Version054`.

This converter fully supports all versions from `Version032` to `Version054`.

About 2% of files don't convert, most likely due to converter bugs.

## CREDITS

The converter was was originally written by alpaca (Stefan Reutter).

What you see in this directory is based on alpaca's NTW UI converter version 1.1 from 25th August 2010.

It was since enhanced and extended to support ETW and S2TW by taw (Tomasz Wegrzanowski).
