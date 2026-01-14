Archival notice
===============

This project is now [hosted on
Codeberg](https://codeberg.org/jstolarek/dc-card-maker-script).

Dreamcast GDMenu maker script for Linux
=======================================

The `dc-card-maker.sh` is a simple bash script that allows to prepare an SD
memory card to be used with GDEMU optical drive emulator for the Sega Dreamcast
console and the GDMenu homebrew.  The script extracts games from zip archives,
puts them on an SD card in appropriately named directories and generates a
GDMenu disc image with a pre-generated list of menu entries, which avoids
scanning the SD card every time GDMenu is launched.

**This script comes with no warranty of any kind, use at your own risk.** Read
the "Usage" section carefully to understand what the script does before using
it.  I did my best to make the script safe and not cause any data loss *when
used as intended*.  That being said, **backup data on your SD card before using
this script**.  If anything goes wrong the script should terminate without
causing any data loss, but potentially leaving mess in the target directory.
This mess is recoverable but will require some scripting on your side (or a lot
of manual work).


Requirements
============

  * `genisoimage`
  * `hexdump`
  * `sed`
  * `unzip`
  * `cdi4dc`
  * `cdirip`
  * Python 3 (to run `gditools.py` and `iso9660.py` in `tools/` directory)

Script tests presence of `genisoimage`, `cdi4dc`, `cdirip`, and `unzip` at
start.  `sed` and `hexdump` should be available by default on all Linux
distributions.


A note on `cdi4dc` and `cdirip`
-------------------------------

`cdi4dc` and `cdirip` usually don't come in distribution repositories and you
likely need to build them from sources.  Grab the [sources for
`cdi4dc`](https://github.com/Kazade/img4dc) and [sources for
`cdirip`](https://github.com/jozip/cdirip), compile them, and place the compiled
binaries in the tools directory.  If you already have these programs on your
system you can either add a symlink to them in the `tools/` directory or edit
the script to remove the `./tools/cdi4dc` and `./tools/cdirip` checks at the
beginning and then use the system copies of `cdi4dc` and `cdirip` towards the
end of the script.


Usage
=====

The `dc-card-maker.sh` script has to be invoked with three arguments

```
./dc-card-maker.sh game_list.txt source_dir target_dir
```

where:

  * `game_list.txt` is a text file that contains a list of zip archives with
    games to place on the SD card, one archive per line.  Games will be added to
    GDMenu in the order specified in the file, so you can arrange the order to
    your liking.  The easiest way to generate the file for the first time is to
    have a single directory that contains the archives (see next bullet) and
    list its contents to a file (`ls source_dir > game_list.txt`).  After each
    run the script places a copy of `game_list.txt` in the `target_dir` - this
    file can be later used to create an updated list when adding new games to
    the card.  **IMPORTANT:** don't point this first argument to
    `target_dir/game_list.txt`.  This will result in the script trying to read
    the file and at the same time deleting it and writing to it.  This is a bad
    idea.  Instead, copy the `target_dir/game_list.txt` somewhere and pass that
    copy as the first argument.

  * `source_dir` is a directory that contains ZIP archives specified in
    `game_list.txt` above.  The script was designed with TOSEC archives in mind,
    but it should work with any archive that contains a GDI or CDI disc image,
    provided the files are **not placed in a subdirectory inside the archive**.
    The exact name of `*.gdi`/`*cdi` file is unimportant - the script takes care
    to rename it appropriately.

  * `target_dir` is the destination directory where the script will place the
    extracted games and the generated GDMenu image.  This directory should be
    the root of you SD card, but you can also use a directory on your disk and
    only later copy the generated directories to an SD card.  (I use this
    approach since having the target directory on an SSD is much faster - if
    anything goes wrong rerunning the script takes a lot less time.)  Each game
    image is placed in a numbered directory ([as required by
    GDEMU](https://gdemu.wordpress.com/details/gdemu-details/)), with directory
    `01/` being reserved for the GDMenu image.  Each game subdirectory, in
    addition to the GDI/CDI image, contains `archive.txt` file with the name of
    a ZIP archive from which the game was extracted.  It is important that
    `archive.txt` files remain unchanged - otherwise updating the card will not
    work correctly.

When using `dc-card-maker.sh` script for the first time use an empty
`target_dir`.  Once populated by the script the target directory can be further
updated, allowing to add, remove, and reorder games without the need to extract
and copy game archives again.  All you need to do is update the list of games in
`game_list.txt` file supplied as the first parameter to the script.  You can add
new archives to the list, as well as reorder and delete existing ones. If the
game image is already present in the target directory it will be used, with no
additional copying being done.  Newly added games will be extracted from the
archives and added to the target directory.

**IMPORTANT** When updating the card all numbered directories are temporarily
renamed to end with an underscore (`01` becomes `01_`, and so on).  They are
then renamed back, possibly with different names if the games were reordered or
new games were added earlier in the list.  Games that were removed from the list
in `game_list.txt` are left in these temporary subdirectories.  These
directories are reported to the user when the script ends.  At the very least
the list will contain `01_` with a backup copy of previous GDMenu image.  (Note
that by now that image is probably outdated anyway if the list of games has been
modified.)  It is user's responsibility to remove these backup directories.  The
script will refuse to run if the target directory contains directories ending
with an underscore.  This is all done to minimise the risk of data loss due to
user mistakes.


Custom menu entry names
-----------------------

On its first run the script extracts game names from the GDI/CDI images.
Extracted name is placed in a `name.txt` file inside the game's directory on the
SD card.  You can edit these `name.txt` files to provide custom names to display
in GDMenu.  For example, you might want to change all names to be displayed
using lowercase letters, but keep the first letter of each word capitalized.
Here's an incantation that does that:

```
find target_dir -name "name.txt" -exec sed -i -e "s/[A-Z]/\L&/g; s/\b\(.\)/\u\1/g" {} \;
```

Once you edited `name.txt` files to your liking run the script again with the
same parameters to generate an updated GDMenu image with new names.


Contributing guidelines
=======================

  * make a ticket, ensure that your contribution is desired and will be accepted
  * update the documentation if needed
  * no tabs, spaces only
  * no trailing whitespaces
  * newline at end-of-file
  * send PRs or just fork the project and do whatever you want (well, whatever
    the license permits)


Bundled software, credits, and licenses
=======================================

`dc-card-maker.sh` is distributed under the terms of GPL2 license - see
`licenses/LICENSE-dc-card-maker-script` file.

This repo also contains the following additional software and data files created
by other people:

  * `tools/iso9660.py` was written by Barney Gale and is distributed under the
    terms of MIT license.  See `licenses/LICENSE-iso9660`.  Original repository:
    <https://github.com/barneygale/iso9660>.  Ported to Python 3 by HaydenKow:
    <https://gitlab.com/HaydenKow/dcisotools-py3>

  * `tools/gditools.py` is taken from `gditools` library written by FamilyGuy,
    and is distributed under the terms of GPL3 license.  See
    `licenses/LICENSE-gditools` file.  Original repository:
    <https://sourceforge.net/projects/dcisotools/>.  Ported to Python 3 by
    HaydenKow: <https://gitlab.com/HaydenKow/dcisotools-py3>

  * `data/1ST_READ.BIN` contains a binary image of GDMenu written by neuroacid.
    Exact license unknown, but this binary has been released to the public by
    the author and is freely distributed on the internet.  See
    `README-gdmenu.txt` for details.

  * `data/ip.bin` and `GDEMU.ini` are taken from GDEMU_SD written by MadSheep.


Further reading
===============

  * [Structure of `ip.bin`](https://mc.pp.se/dc/ip0000.bin.html)
  * [GDEMU details](https://gdemu.wordpress.com/details/gdemu-details/)
  * [GDEMU operation](https://gdemu.wordpress.com/operation/gdemu-operation/)
