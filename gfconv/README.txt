To unpack:

* put all groupformations*.bin files you want to convert in this directory
* run gfunpack from command line
* groupformations*.txt files will be created

To pack [when it's ready]:
* put groupformations*.txt file you want to convert in this directory
* run gfpack from command line
* groupformations*.bin will be created


Converters don't overwrite data, if file exists, a new one with extra suffix will be created.

So if you start with:
* groupformations.bin
* groupformations-ntw.bin
* groupformations-darthmod.bin

You'll get:
* groupformations.txt
* groupformations-ntw.txt
* groupformations-darthmod.txt

(backup anyway, just in case)
