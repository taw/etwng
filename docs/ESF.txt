== ESF data types ==

It's much less messy than initially seemed.
Lower nibble is type, upper nibble is container type.

Absolutely certain types are - and notice regularity:
* 0x01 0x41 - boolean; array of booleans
* 0x04 0x44 - int32; array of int32s
* 0x06 0x46 - byte; array of bytes
* 0x08 0x48 - uint32; array of uint32s
* 0x0a 0x4a - float; array of floats
* 0x0c 0x4c - vec2; array of vec2s
* 0x0d 0x4d - vec3; array of vec3s
* 0x0e      - utf-16-le string
* 0x0f      - ascii string

And record types:
* 0x80      - record [uint16 type tag; uint8 version; uint32 end_ofs; uint32 element_count; arbitrary tagged data]
* 0x81      - array of record [uint16 type tag; uint8 version; uint32 end_ofs; uint32 element_count]
              each element is [uint32 elem_end_ofs; arbitrary tagged data]

One very interesting find is:
* 0x42 - array of byte pairs [!!!] - for wind map mostly, (x wind byte, y wind byte) or something like it

A few big unknowns left:

These types are definitely 16 bit, but signedness is uncertain, and what is 0x10?
* 0x00 - [u?]int16
* 0x07 - [u?]int16
* 0x10 - [u?]int16
* 0x47 - array of [u?]int16s

Some records like especially CAMPAIGN_LOCALISATION have extremely peculiar contents.
It seems to be either one non-empty unicode string,
or two empty unicode strings (0x0e 0x00 0x00 0x0e 0x00 0x00).

A lot of records have variable content, often like:
- [true] X or
  [false]
Or like:
- [u2 or u4 or other int type count] [count times X]

But they are not "real" ESF arrays you'd expect.

Entire poi.esf is huge blob of those, first approximation:
  u4(entries count)
    u4(serial_id)
    i4(some type id?)
    bool
    i4 i4
    str(name),u4(?)
    str(name),u4(?)    repeated for no reason?
    flt
    i4(neighbours_count)
      str(neighbour_name)
      flt
    flt
    u4
    u4
    u4
    bool

It seems that esf leaves far too many options, so they picked one at random.
