Just run build_luadec script to fetch, patch, and build luadec
capable of dealing with ETW .luac

There are problems in both luadec and
in my quick hacks to make lua use single precision floats instead of doubles.
Further work needed but it will do for now.

Build script works on OSX and Linux.
It should be possible to adapt it to other platforms supported by lua
without too much modest effort.

== Requirements ==

You need to have all basic libraries installed.

For Ubuntu, this should do the trick:
$ sudo apt-get install build-essential libreadline-dev

== Usage ==

Use pack manager to extract .luac files, then decompile each one of them with:

./luadec -d xxx.luac >xxx.lua
