= Installation =
You need Ruby.

Any version should do, 1.8.7 or 1.9, CRuby or JRuby,
but it's only really tested under CRuby 1.8.7.

OSX and Linux should have adequate version of Ruby out of the box.
For Windows you'll need to install one yourself.

= Usage = 
To unpack:
* put all groupformations*.bin files you want to convert in this directory
* run gfunpack from command line
* groupformations*.txt files will be created

To pack:
* put groupformations*.txt file you want to convert in this directory
* run gfpack from command line
* groupformations*.bin will be created


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
