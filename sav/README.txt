This directory contains very much unfinished tools for parsing .sav format for Medieval 2 and other games based on Rome engine.

A few observations:

== sections ==
* there are sections of format:
  uint32 current offset
  uint32 section size
  data
  
  section size is inclusive of 8 byte header.
  Data within sections is often regular, like (guessing here):
    uint16   - number of elements
    uint32[] - elements
    uint8    - some flag
  
Sections often occur one after another with no gaps, but sometimes sections nest.

== strings ==

strings come in ton of formats:
* ASCII and UTF-16
* null-terminated and uint16-char-count-prefixed (often both at once!)


== partial format deparse ==

* uint16      - magic (06 09)
* ca_unicode  - relative path to "data" directory
* header:
  * (some completely obscure data, seems to be uint32[] or close)
  * ca_unicode campaign name (imperial_campaign)
  * (more obscure data)
  * global settings table [???]:
    * uint32 item count
    * [asciiz string, uint32]
    * uint16 (04) - no idea
  then top level section, presumably:
    ca_unicode
    ca_unicode
    section
    section
    ca_unicode
    etc.
