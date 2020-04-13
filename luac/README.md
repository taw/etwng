I'd recommend just using LUA decompiler at http://www.decompiler.com/ - it seems to handle all the files, and it's fully online and very easy to use.

If that doesn't work for you, there are 2 .luac decompilers here.

I'd generally recommend using unluac.jar, as it can handle wider range of .luac files, and doesn't require compilation.

The older luadec is a hacked lua 5.0 decompiler, and since Total War games use lua 5.1, it can sadly can only handle simpler .luac files.

## Usage of unluac.jar

Project page is https://sourceforge.net/projects/unluac/, but local copy is included here for convenience.

To use:

    $ java -jar unluac_2015_06_13.jar file.luac

## Building luadec

Just run `build_luadec` script to fetch, patch, and build luadec capable of dealing with ETW .luac

There are problems in both luadec and in my quick hacks to make lua use single precision floats instead of doubles.

Build script works on OSX and Linux. It should be possible to adapt it to other platforms supported by lua without too much effort.

Total War lua engine is 32-bit, while all operating system nowadays are 64-bit, so build scripts passes appropriate flags to the compiler.

## Requirements for building luadec

You need to have all basic libraries installed.

If you have 64-bit operating system, you still need to compile it in 32-bit mode.
Build script handles all relevant build flags, but you still need to have
32-bit versions of relevant libraries installed.

For Ubuntu, this should do the trick:

    $ sudo apt-get install build-essential lib32readline6-dev libc6-dev-i386 lib32ncurses5-dev

## Usage of luadec

Use pack manager to extract .luac files, then decompile each one of them with:

    ./luadec -d xxx.luac >xxx.lua

## luadec

There's more recent version of luadec on https://github.com/sztupy/luadec51
