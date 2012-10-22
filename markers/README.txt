There are two formats

== Bridge markers ==

Usage:

./markers_unpack bridge.markers bridge.txt
./markers_pack bridge.txt bridge.markers

Or with JRuby:

jruby ./markers_unpack bridge.markers bridge.txt
jruby ./markers_pack bridge.txt bridge.markers


== Shogun 2 .markers ==

Various .markers files in Shogun 2 use a different format
and have a separate converter.

./world_markers_unpack world.markers world.txt
./world_markers_pack world.txt world.markers

== World markers ==

world.markers uses format similar to one later used for Shogun 2,
but it doesn't have a working decoder yet. Contact me if you really need it.
