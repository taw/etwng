This project is collection of tools for modding Empire Total War
and related games like Napoleon Total War, especially:

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

= Layers =

Usually there are multiple layers of data, and figuring out one layer
isn't success yet.

For example if we find an image and it looks like something directly
displayed on screen - like an unit card, or an icon - our work is done.
If it looks like a texture, we probably need to figure out UV coordinates,
and similar minor points.

But if it doesn't look like anything? Is it map data of some sort?
A height map with gray levels corresponding to height? A few large
areas uniformly colored with 5 basic colors? What's the scale?
Which way axes go? What's the meaning of all that?
Opening one layer doesn't yet solve it.

This is most important for ESF - ESF is more or less binary
equivalent of XML, so we're down one layer. But what's the
meaning of different nodes, and different arguments?

And embedded inside such ESF might be binary data,
in which case we're have to dig even deeper.

It is similar with DB tables - their low-level schemas are usually known,
their meaning not always.

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
