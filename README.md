Dreamcast GDMenu maker script for Linux
=======================================

The `dc-card-maker.sh` is a simple bash script that allows to prepare an SD
memory card to be used with GDEMU optical drive emulator for the Sega Dreamcast
console.  It extracts games from zip archives, puts them on an SD card in
appropriately named directories (as required by GDEMU) and generates a GDMenu
ISO disc with a pre-generated list of menu entries, which avoids scanning the SD
card every time GDMenu is launched.

**This script comes with no warranty of any kind, use at your own risk.** Read
the "Usage" section carefully to understand what the script does before using
it.  I did my best to make the script safe and not cause any data loss and I
think it shouldn't happen *when used as intended*.  That being said, **backup
data on your SD card before using this script**.


Requirements
============

  * `genisoimage`
  * `hexdump`
  * `sed`
  * `unzip`
  * `cdi4dc`
  * Python (to run `gditools.py` and `iso9660.py` in `tools/` directory)

A note on `cdi4dc`
------------------

TODO: document `cdi4dc`  https://github.com/Kazade/img4dc
TODO: move tools and data files to subdirectories
TODO: fix VGA bit in ip.bin

Usage
=====

Creating new card
-----------------

TODO: finish

```
ls in/ > list.txt
```

Assumptions: tosec archives, input dir contains archives, text file contains
archive names.  extract archives, move files, creates menu entries, leaves a
text file for future use, won't start if leftovers

Updating existing card
----------------------


Custom menu entry names
-----------------------


Behind the scenes
=================

TODO: finish

https://mc.pp.se/dc/ip0000.bin.html


Contributing guidelines
=======================

  * update the documentation if needed
  * no tabs
  * no trailing whitespaces
  * newline at end-of-file
  * send PRs or just fork the project and do whatever you want


Bundled software, credits, and licenses
=======================================

`dc-card-maker.sh` is distributed under the terms of GPL2 license -- see
`licenses/LICENSE-dc-card-maker-script` file.

This repo also contains the following additional software and data file created
by other people:

  * `1ST_READ.BIN` contains a binary image of GDMenu written by neuroacid.
    Exact license unknown, but this binary has been released to the public by
    the author and is freely distributed on the internet.  See
    `README-gdmenu.txt` for details.

  * `iso9660.py` was written by Barney Gale and is distributed under the terms
    of MIT license.  See `licenses/LICENSE-iso9660`.  Original repository:
    https://github.com/barneygale/iso9660

  * `gditools.py` is taken from `gditools` library written by FamilyGuy, and is
    distributed under the terms of GPL3 license.  See
    `licenses/LICENSE-gditools` file.  Original repository:
    https://sourceforge.net/projects/dcisotools/

  * `ip.bin` and `GDEMU.ini` are taken from GDEMU_SD written by MadSheep.  I
    altered the VGA byte (`0x3E` offset) in `ip.bin` to 1.  For some reason it
    was set to 0, which seems incorrect - GDMenu works in VGA mode without
    problems.
