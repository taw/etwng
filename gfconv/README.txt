= Installation =
You need to install Ruby.

OSX and Linux should have adequate version of Ruby out of the box.
For Windows you'll need to install one yourself, JRuby is easiest to install [ http://jruby.org/download ].

= Usage =
To unpack:
* put all groupformations*.bin files you want to convert in this directory
* run gfunpack from command line
* groupformations*.txt files will be created

To pack:
* put groupformations*.txt file you want to convert in this directory
* run gfpack from command line
* groupformations*.bin will be created

If you're converting S2TW use gfpack_s2tw/gfunpack_s2tw files instead.

= File names =
Converters don't overwrite data, if file exists, a new one with extra suffix will be created.

So if you start with:
* groupformations.bin
* groupformations-ntw.bin
* groupformations-darthmod.bin

You'll get:
* groupformations.txt
* groupformations-ntw.txt
* groupformations-darthmod.txt

And when converting back (if you didn't move originals):
* groupformations-2.bin
* groupformations-ntw-2.bin
* groupformations-darthmod-2.bin


It won't hurt to backup anyway, just in case.
