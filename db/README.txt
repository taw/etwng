=== DB<->TSV converter ===

You can unpack either the whole tree or one file at a time:

./db_unpack db/ converted/
./db_unpack db/foo_tables/foo converted/foo_tables/foo.tsv

When converting directories, the entire subdirectory structure
will be recreated in target directory as well, skipping only
files which are impossible to convert.

To convert back do likewise:

./db_pack tsvs/ db/
./db_pack tsvs/foo_tables/foo.tsv db/foo_tables/foo

If you have non-English locale which uses comma instead of period as
decimal separator (3,14 vs 3.14), certain version of OpenOffice.org
and possibly other programs might have troubles with such TSV.

In such case you can either switch to English (US) locale,
which is known to work, or pass --comma option to db_unpack/db_pack:

./db_unpack --comma db/ tsvs/
./db_pack --comma tsvs/ db/

db_pack actually always accepts TSVs with either decimal format,
so there's no way to make a mistake while converting back.
It only takes --comma option for compatibility.

=== Statistics ===

From my collection of db files (various versions from main.pack, patch*.pack, mods, etc.)
number converted is:

ETW   965/ 975
NTW   443/ 482
S2TW  766/ 904
all  2174/2361
