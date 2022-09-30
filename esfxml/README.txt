== Usage ==
$ ./esf2xml foo.esf foo_dir
$ ./esf2xml --quiet foo.esf foo_dir
$ ./xml2esf foo_dir foo.esf

esf2xml automatically prints progressbar unless told not to by --quiet option
(xml2esf might get this too later)

To run with specific Ruby version use like:
$ ruby esf2xml foo.esf foo_dir
$ jruby esf2xml foo.esf foo_dir

== Unpacked Directory ==
Main file in unpacked directory is always esf.xml
There might be other files as well, xml, bitmap, or anything else.

== System Requirements - OSX/Linux ==
It should now work on every system (by every I mean OSX, Linux, and Windows) both ways.

For OSX) and Linux esf2xml should work out of the box, for xml2esf you only need to run this command, or install nokogiri some other way:
$ sudo gem install nokogiri

== System Requirements - Windows ==
The easiest way to get it running under Windows is by installing Ruby or JRuby

Here's the link:
* https://rubyinstaller.org/

== LZMA ==

lzma.exe is from LZMA SDK [ http://www.7-zip.org/sdk.html ] and
included here just for your convenience. It's Copyright (C) Igor Pavlov.
