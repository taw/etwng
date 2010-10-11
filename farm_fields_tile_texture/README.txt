Full format spec:

* uint32 number of objects
* N times:
      o uint32 object offsets
* uint32 file size

Objects come in a few varieties depending on subtype.

The most common is filepair, both files being jpegs:
      o uint32 size of fileA
      o uint32 size of fileB
      o data of fileA
      o data of fileB

First of the pair seems to depend on kind of file - that is in which directory it was found
Second of the pair looks like a heightmap always.


There are also other objects type.
Details will follow later.
