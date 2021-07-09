Convert Total War UI layout files to XML and back. 

### Dependencies

Either install JRuby:

* install Java - https://www.java.com/en/download/manual.jsp
* install JRuby - https://www.jruby.org/getting-started
* run `jgem install nokogiri`

Or install regular Ruby:

* install Ruby https://rubyinstaller.org/
* run `gem install nokogiri`

Pretty much any version will work.

### How to use

To unpack:

```
jruby bin/ui2xml path/to/uifile path/to/file.xml
```

To pack back:

```
jruby bin/xml2ui path/to/file.xml path/to/uifile
```

### Supported

Almost all `VersionXXX` files work, details by game below.

The converter also supports all `.cml`, `.fc`, and `.twui.images` files.
They're a separate format, but they also have `VersionXXX` header and they live just next to UI files, so I added them too.

There's no guarantee that XML format will remain stable. I might need to tweak it a bit.

### Limitations

The converter fully decodes structure of the UI layout files, but it has limited knowledge as to their meanings.

So you will often see blocks of integers or booleans, and while I'm reasonably confident that they're indeed integers or booleans, it's not always clear what they actually do.

If you have any information about that, it's very welcome.

### Supported level by game

Checked on every `VersionXXX` from every game I could find. Percentage converting to xml and back perfectly by game:

* Empire: 204/205 (100%) - the only failing one is definitely corrupted
* Napoleon: 201/201 (100%)
* Shogun 2: 285/285 (100%)
* Rome 2: 306/306 (100%)
* Attila: 190/190 (100%)
* Thrones of Britannia: 205/205 (100%)
* Warhammer 1: 270/271 (100%)
* Warhammer 2: 348/349 (100%)
* Troy: 393/395 (99%)
* Three Kingdoms: 432/433 (100%)

* Total: 2834/2840 (100%)

### Credits

Software written by taw (Tomasz Wegrzanowski).

Special thanks to alpaca for the original research for Napoleon and the original UI converter, and to Cpecific for research on Rome 2+ games.
