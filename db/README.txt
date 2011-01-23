=== DB<->TSV converter ===

You can unpack either the whole tree or one file at a time:

./db_unpack db/ converted/
./db_unpack db/foo_tables/foo converted/foo_tables/foo.tsv

When converting directories, the entire subdirectory structure
will be recreated in target directory as well.

=== DB format ===

Tables in db formats need external schema for decoding.

For all except two this schema is known (except minor issues
like int signedness etc.) and described in DB.xsd


For models_building_tables schema is:

* string building_identifier (like "american_ruin01")
* string path (like "buildings\american_ruin01\american_ruin01_tech.cs2.parsed")
* uint32 unknown (always 0 or 1)
* uint32 count (from 0 to 346 in data, count of the following)
* count times
      o string efline_identifier (like "EFline_piece01_destruct01_line01")
      o uint32 unknown (always one of 0,1,2,3)
      o 7x float unknown
      o either float or uint32 (always 0, zero looks the same in both formats)
      o float

Schema for models_naval_tables is still not fully known.
Some partial information is here:
* http://www.twcenter.net/forums/showthread.php?p=8157666#post8157666

= DB format =

* Magic number, one of:
	* 1 byte  - 01 - original schema
	* 9 bytes - fc fd fe ff XX 00 00 00 01 - revised schema version XX
* uint32 number of rows
* data for in each row one after another,
  without separators, metadata, or padding

To even figure out where rows begin and end we need to know schema.

With exception of models_building_tables and models_naval_tables
very few types are used, and every row has identical number of columns
of identical types.

Most common types are:
* string - 2+2N bytes:
  * uint16 character count
  * character data as UTF-16-LE
* nullable string, either:
  * 00 - null
  * 01 string (as specified above)
* float (single precision) - 4 bytes
* int32 - 4 bytes
* boolean - 1 byte - 00 or 01

non-nullable string can be empty (00 00)
There doesn't seem to be anything preventing
non-null empty string (01 00 00), but this doesn't seem
to occur (no hard evidence either way).

Uncommon types:
* fixed length binary data - N bytes
* int16/uint16 - 2 bytes
* uint32 - 4 bytes - nearly every 4 byte value with high bit set
  is either negative int32 or float. Obvious uint32s seem rare.

Except models_building_tables/models_naval_tables only two data types
are not fixed length - string and nullable string, and UTF-16 strings
are very easily identified. This led to determination of almost all
schemas with small manual help.

= Primary keys =

DB tables are relational - primary key is normally either
first column of string type for regular tables, or
first 2-3 columns all of string type for junction tables.
