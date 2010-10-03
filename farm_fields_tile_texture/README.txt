Full format spec:

* uint32 number of filepairs N
* N times:
      o uint32 filepair offsets
* uint32 file size
* N times file pair:
      o uint32 size of fileA
      o uint32 size of fileB
      o data of fileA
      o data of fileB

All files are jpegs.
First of the pair seems to depend on kind of file - that is in which directory it was found
Second of the pair looks like a heightmap always.


Warning: Bunker hill file seems to be encrypted.
