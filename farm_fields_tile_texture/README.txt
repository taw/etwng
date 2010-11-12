= Usage =

./fftt_unpack input.farm_fields_tile_texture output_dir
./fftt_pack input_dir output.farm_fields_tile_texture

It will handle 80% of fftt files of the most common subformat.
There are a few other subformats which will produce error message.

= Format spec =

* [optionally, a single extra byte of header data]
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
