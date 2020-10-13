Dreamcast GDMenu maker script for Linux
=======================================

The `dc-card-maker.sh` is a simple bash script that allows to prepare an SD
memory card to be used with GDEMU optical drive emulator for the Sega Dreamcast
console.  It extracts games from zip archives, puts them on an SD card in
appropriately named directories (as required by GDEMU) and generates a GDMenu
ISO disc with a pre-generated list of menu entries, which avoids scanning the SD
card every time GDMenu is launched.

Requirements:

  * `genisoimage`
  * `hexdump`
  * `sed`
  * `unzip`
  * `cdi4dc`
  * Python (to run `gditools.py` and `iso9660.py`)

TODO: `cdi4dc`?  https://github.com/Kazade/img4dc

**This script comes with no warranty of any kind, use at your own risk.**


Usage
=====

TODO: finish

```
ls in/ > list.txt
```

Assumptions: tosec archives, input dir contains archives, text file contains
archive names.  extract archives, move files, creates menu entries, leaves a
text file for future use, won't start if leftovers


Behind the scenes
=================

TODO: finish

https://mc.pp.se/dc/ip0000.bin.html


Bundled software, credits, and licenses
=======================================

`dc-card-maker.sh` is distributed under the terms of GPL3 license -- see
`LICENSE-GPL3` file.

This repo also contains the following additional software written by other
people:

  * `1ST_READ.BIN` contains a binary image of GDMenu written by neuroacid.
    License unknown, but this binary is freely distributed on the internet.  See
    `gdmenu-readme.txt`

  * `iso9660.py` was written by Barney Gale and is distributed under the terms
    of BSD license -- see `LICENSE-BSD`.  Original repository:
    [https://github.com/barneygale/iso9660]

  * `gditools.py` was written by FamilyGuy and is distributed under the terms of
    GPL3 license -- see `LICENSE-GPL3` file.  Original repository:
    [https://sourceforge.net/projects/dcisotools/]

  * `ip.bin` is taken from GDEMU_SD written by MadSheep
