== UNPACKER ==

etw_unpacker.py is a straightforward unpacker for .pack files

== FUSE DRIVER ==

fuse/ directory contains filesystem driver which lets you mount
.pack files and groups of .pack files directly as image,
without unpacking.

Check README.txt in fuse/ directory for compilation instructions.

== FORMAT ==

.pack format consists of:

Header:
* uint32 magic "PFH0"
* uint32 pack type (boot 0, main 1, patch 2, mod 3, movie 4)
* uint32 dependencies count
* uint32 dependencies header size
* uint32 files count
* uint32 files header size

Dependencies section has size and entries count as specified above,
each entry is:
* NUL-terminated ASCII string as file name, for example "patch2.pack\x00"
  dependency in patch3.pack file.

File list section	 has size and entries count as specified above,
each entry is:
* uint32 file size
* NUL-terminated ASCII string as full file path.
  Both / and \ seem to be valid path separators and not distinguished.

File data section:
* Data of every file specified above, in sequence, without any separators,
  padding or anything else.
