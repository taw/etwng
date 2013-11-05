Just run build_luadec script to fetch, patch, and build luadec
capable of dealing with ETW .luac

There are problems in both luadec and
in my quick hacks to make lua use single precision floats instead of doubles.
Further work needed but it will do for now.

Build script works on OSX and Linux.
It should be possible to adapt it to other platforms supported by lua
without too much modest effort.

The build script currently expects 32-bit operating system.
(since .luac for Total War files are 32-bit)
It's possible to cross-compile it on 64-bit operating system,
you just need to specify proper flags.

== Requirements ==

You need to have all basic libraries installed.

If you have 64-bit operating system, you still need to compile it in 32-bit mode.
Build script handles all relevant build flags, but you still need to have
32-bit versions of relevant libraries installed.

For Ubuntu, this should do the trick:
$ sudo apt-get install build-essential lib32readline6-dev libc6-dev-i386

== Usage ==

Use pack manager to extract .luac files, then decompile each one of them with:

./luadec -d xxx.luac >xxx.lua

== luadec ==

There's more recent version of luadec on https://github.com/sztupy/luadec51
