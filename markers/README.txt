There are two formats

== Bridge markers ==

Usage:

jruby markers_unpack bridge.markers bridge.txt
jruby markers_pack bridge.txt bridge.markers

== Shogun 2 .markers ==

Various .markers files in Shogun 2 use a different format
and have a separate converter.

jruby world_markers_unpack file.markers file.txt
jruby world_markers_pack file.txt file.markers

== World markers ==

world.markers uses format similar to one later used for Shogun 2,
but it doesn't have a working decoder yet. Contact me if you really need it.
