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

A lot of information and code recently became available but it's
highly disorganized, and it's difficult to keep up with all the progress.

= Status of file formats =

Not ETW-specific, easily moddable:
* .tga - raster data
* .jpg - raster data
* .dds - raster data
* .bik - video
* .mp3 - audio
* .wav - audio

More or less ETW-specific:
* .pack - file container, fully known, and widely supported
* db - relational tables, schema external, mostly known,
       modding tools lack a few features but are usually adequate
* .lua - lua 5.1 code, ETW interface weakly documented
* .luac - compiled .lua - mostly recoverable with difficulty
* .esf - serialized hierarchical data (binary XML),
         mostly known, modding support weak
* .farm_fields_tile_texture - list of pairs of JPEG files,
  very recently understood
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
