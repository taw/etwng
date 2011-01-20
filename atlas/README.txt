= Usage =

./atlas_unpack file.atlas file.tsv
./atlas_pack file.tsv file.atlas

= Format spec =

* uint32 1
* uint32 0
* uint32 number of entries, each being:
  * string of 256 utf-16 characters (zero-padded)
  * string of 256 utf-16 characters (zero-padded)
  * 6 single precision floats
