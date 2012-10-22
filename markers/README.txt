There are two formats

== Bridge markers ==

Usage:

./markers_unpack bridge.markers bridge.txt
./markers_pack bridge.txt bridge.markers

Or with JRuby:

jruby ./markers_unpack bridge.markers bridge.txt
jruby ./markers_pack bridge.txt bridge.markers


== World markers ==

world.markers and various .markers files in Shogun 2 use a different format
and have a separate converter.

./world_markers_unpack world.markers world.txt
./world_markers_pack world.txt world.markers

[THIS DOESN'T WORK YET]
