== Usage ==
$ ./esf2xml foo.esf foo_dir
$ ./esf2xml --quiet foo.esf foo_dir
$ ./xml2esf foo_dir foo.esf

esf2xml automatically prints progressbar unless told not to by --quiet option
(xml2esf might get this too later)

To run with specific Ruby version use like:
$ ruby ./esf2xml foo.esf foo_dir
$ jruby --server -J-Xmx2048m ./esf2xml foo.esf foo_dir

You might want to specify higher memory limit like -J-Xmx2048m option,
default JVM max heap size is ridiculously small 500MB, half of it
going to JVM overhead.

Passing --server to jruby speeds it up by about 10%, so do it.


== Unpacked Directory ==
Main file in unpacked directory is always esf.xml
There might be other files as well, xml, bitmap, or anything else.


== System Requirements - OSX/Linux ==
It should now work on every system (by every I mean OSX, Linux, and Windows) both ways.

For reasonably recent OSX (10.5 or newer) and Linux esf2xml should work out of the box,
for xml2esf you only need to run this command, or install nokogiri some other way:
$ sudo gem install nokogiri

If you want to use it with JRuby you'll need this instead:
$ sudo jgem uninstall nokogiri
$ sudo jgem install nokogiri --pre


== System Requirements - Windows ==
The easiest way to get it running under Windows is by installing
JRuby single installer with Java Runtime Environment bundled.
Here's the link:
http://jruby.org.s3.amazonaws.com/downloads/1.5.3/jruby_windowsjre_1_5_3.exe

For Windows JRuby you need prerelease version of Nokogiri (--pre flag).
If you have installed other version before, you must also uninstall it first.
These two commands should do it:

$ jgem uninstall nokogiri
$ jgem install nokogiri --pre

== LZMA ==

lzma.exe is from LZMA SDK [ http://www.7-zip.org/sdk.html ] and
included here just for your convenience. It's Copyright (C) Igor Pavlov.
