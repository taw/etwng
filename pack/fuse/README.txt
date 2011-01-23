fuse/ directory contains filesystem driver which lets you mount
.pack files and groups of .pack files directly as image,
without unpacking.

Driver works on OSX and Linux.

FUSE works on everything (except Windows,
but there are some porting efforts too),
so ports to other systems should be easy.

On both OSX and Linux compilation and usage
is identical, the only difference is drivers required.

On OSX you need to have MacFUSE drivers installed.
You can get MacFUSE from http://code.google.com/p/macfuse/

On Linux you need fuse drivers and libfuse-dev.
How to install them depends on your system, on Ubuntu it is simply:
$ sudo apt-get install libfuse-dev
On other distributions something similar.

== Compilation ==

$ cd fuse
$ make

== Use ==

To mount at mount/path:

$ mkdir -p mount/path
$ ./packfs empire/directory/*.pack mount/path
