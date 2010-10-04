This project is collection of tools for Empire Total War modding, especially:

* ETW-specific file format information
* Converters from ETW to mainstream formats and back
* Tools for directly modifying ETW formats as alternative to conversion
* Instructions on getting started with them all
* Links to ETW modding tools available elsewhere
* Any other basic modding instructions

What it does not contain:
* Any copyrighted data from the game
  (except possibly minimal test samples etc. under fair use)
* Generic tools for editing mainstream file formats.
* Anything related to high-level game-balance issues etc.
  The focus is just getting data out and moddable.
  It's up to you what you do with it.
* Encrypted files - they might have identical extension,
  but if they're encrypted, you're out of luck, even
  if you purchased relevant DLC.

A lot of information and code recently became available but it's
highly disorganized, and it's difficult to keep up with all the progress.

This project is very messy, with different parts ranging from mature
and fully documented to quick nasty hacks and wild guesses.
This is to be expected given rapid progress of our knowledge of
ETW formats.



= How to recognize encrypted data =

This is easy - just compress it with gzip and see if it got smaller.
Encrypted data by its nature is impossible to compress without a key.
Almost every other data type in ETW has a lot of redundancy.
Even compressed types like .mp3, .jpg, .bik, etc. usually
have uncompressed parts like headers.

gzip is really good at turning itself on and off for different
parts of file, so even if such data is just 1%, compressed file
size will be reliably slightly smaller.

Fully encrypted files have no such redundancy, so gzipping
them makes them *larger* (as does gzipping gzipped files).

If something compresses - even just 1%, it is definitely not encrypted.
(it might still contain mix of encrypted and unencrypted parts)
If something doesn't compress, it is very likely to be encrypted.
Difference between 99% and 100% might seem small, but it's not.

= Status of file formats =

Not ETW-specific, easily moddable, outside scope of this project:
* .tga - raster data
* .jpg - raster data
* .dds - raster data
* .bik - video
* .mp3 - audio
* .wav - audio


More or less ETW-specific, details in individual directories
when present:

* .pack - file container, fully known, and widely supported
* db    - relational tables, schema external, mostly known,
          modding tools lack a few features but are usually adequate
* .lua  - lua 5.1 code, ETW interface weakly documented
* .luac - compiled .lua - mostly recoverable with difficulty
* .esf  - serialized hierarchical data (binary XML),
         mostly known, modding support weak
* .farm_fields_tile_texture - list of pairs of JPEG files,
                              only very recently understood
* .farm_template_tile - ESF

Status to be investimaged:
* .rigid_model
* .anim_sound_event
* .anim
* .rigid_model_header
* .txt
* .variant_weighted_mesh
* .rigid_spline
* .parsed
* .rigid_model_animation
* .environment
* .spt
* .xml
* .fx
* .animatable_rigid_model
* .desc_model
* .windows_model
* .rigid_mesh
* .cuf
* .fx_fragment
* .settings
* .rigid_naval_model
* .dat
* .db
* .csv
* .tree_model
* .battle_script
* .tai
* .h
* .rigging
* .script
* .gallant
* .deployment_areas
* .loc
* ...
