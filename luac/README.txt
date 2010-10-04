Just run build_luadec script to fetch, patch, and build luadec
capable of dealing with ETW .luac

There are problems in both luadec and
in my quick hacks to make lua use single precision floats instead of doubles.
Further work needed but it will do for now.

Script targets OSX but it should be trivial to support other platforms.

== Manual build ==

If you want to decode more .luac files, here's what you do:

    * You need C compiler, clue about programming etc. This is not for everyone.

First we need lua:

    * Get lua 5.1 sources from http://www.lua.org/ftp/
    * In src/luaconf.h change lines
          o #define LUA_NUMBER_DOUBLE
            #define LUA_NUMBER double
            to
          o #define LUA_NUMBER_FLOAT
            #define LUA_NUMBER float
    * compile lua with command appropriate for your platform like:
          o make macosx - I only tested this one, on 32 bit OS
          o make linux
          o make mingw
          o make generic - this should work too I think

Now luadec:

    * Get luadec51_2.0 sources from http://luadec51.luaforge.net/
    * In print.c line 15 change line in getupval command (line 45 here) from:
          o if (F->f->upvalues) {
    * to
          o if (F->f->upvalues && r < F->f->sizeupvalues) {
    * Compile it pointing to directory where original lua is located (tweak for your platform):
          o gcc -g -I ../../lua-5.1.4/src/ *.c -c
          o gcc ../../lua-5.1.4/src/liblua.a *.o -o luadec

Now back up this luadec executable somewhere so you don't have to go through this nonsense again.

Use pack manager to extract .luac files, then decompile each one of them with ./luadec -d xxx.luac >xxx.lua
