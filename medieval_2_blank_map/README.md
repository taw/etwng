Scripts to generate blank map for Rome Total War or Medieval 2 Total War or any of their expansions or mods.

You can see [the maps at my blog](http://t-a-w.blogspot.com/2012/08/blank-political-maps-for-rome-and.html).

### Requirements

* Any version of ruby (jruby is always a safe choice).
* ImageMagick for convert command.

### Usage

* find `map_regions.tga` in your game or mod
* convert it to pnm format

```
    $ convert map_regions.tga map_regions.pnm
```
* run the script for style 1 map:
```
    $ jruby blank_political_map_style1.rb map_regions.pnm blank_map.pnm
```
* or for style 2:
```
    $ jruby blank_political_map_style2.rb map_regions.pnm blank_map.pnm
```
* convert it to more convenient image format:
```
    $ convert blank_map.pnm blank_map.png
```

You can edit scripts to change color codes it will use. It's just obvious RGB values.

### Limitations

Script assumes the map uses same water colors as vanilla. That seems to be true for all expansions and mods I've seen, but IIRC it's not hardcoded, so if water doesn't look right, you might need to adjust `water` colors list.
