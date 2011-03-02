Converter for .unit_variant for NTW and S2TW.

Usage:
  jruby uv_unpack file.unit_variant file.txt
  jruby uv_pack file.txt file.unit_variant

You can also convert whole directories - just make sure there's
nothing but correct files in them, or they will confuse the converter:

  jruby uv_unpack directory_with_unit_variants directory_with_txts
  jruby uv_pack directory_with_txts directory_with_unit_variants

It works with either Ruby or JRuby, on any operating system.
