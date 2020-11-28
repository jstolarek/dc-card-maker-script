#!/bin/bash

# Dreamcast GDMenu maker script for Linux.  Usage:
#
#   dc-card-maker.sh game_list.txt source_dir target_dir
#
# See README.md for detailed instructions
#
# Copyright (C) 2020 Jan Stolarek
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

# For error printing in red
STARTRED="\e[31m"
ENDRED="\e[0m"

# Check for required commands
command -v genisoimage >/dev/null 2>&1 || {
    echo -e "$STARTRED""This script requires genisoimage to be present in the system. Aborting script""$ENDRED" >&2
    exit 5
}

command -v ./tools/cdi4dc >/dev/null 2>&1 || {
    echo -e "$STARTRED""This script requires cdi4dc to be present in tools/ directory""$ENDRED" >&2
    echo -e "$STARTRED""See README for details.  Aborting script""$ENDRED" >&2
    exit 6
}

command -v ./tools/cdirip >/dev/null 2>&1 || {
    echo -e "$STARTRED""This script requires cdirip to be present in tools/ directory""$ENDRED" >&2
    echo -e "$STARTRED""See README for details.  Aborting script""$ENDRED" >&2
    exit 6
}

command -v unzip >/dev/null 2>&1 || {
    echo -e "$STARTRED""This script requires unzip to be present in the system. Aborting script""$ENDRED" >&2
    exit 7
}

# Process command line args
if [ "$#" != 3 ]; then
    echo "Dreamcast SD card maker script"
    echo ""
    echo "Usage: dc-card-maker.sh game_list.txt source_dir target_dir"
    exit 1;
fi

INPUT_FILE=$1
SOURCE_DIR=$2
TARGET_DIR=$3
OUTPUT_FILE=$3/game_list.txt
GDMENU_INI=ini/LIST.INI
ARCHIVE_FILE=archive.txt
NAME_FILE=name.txt # collides (coincides?) with MadSheep's Windows SD card maker

# Basic sanity checks
if [[ ! -f $INPUT_FILE ]]; then
    echo "Input file does not exist : $1" >&2
    exit 2;
fi

if [[ ! -d $SOURCE_DIR ]]; then
    echo "Source directory does not exist : $2" >&2
    exit 3;
fi

if [[ ! -d $TARGET_DIR ]]; then
    echo "Target directory does not exist : $3" >&2
    exit 4;
fi

# If there are any directories with names consisting of digits only and ending
# with an underscore it means there are leftovers from previous script run.
# Abort the script to avoid problems and potential data loss.
LEFTOVER_DIRS=`find $TARGET_DIR -regextype sed -regex "$TARGET_DIR/*[0-9][0-9]*_"`
if [[ ! -z $LEFTOVER_DIRS ]]; then
    echo -e "$STARTRED""Following directories from previous session found:""$ENDRED" >&2
    for DIR in $LEFTOVER_DIRS; do
        echo "$DIR" >&2
    done
    echo -e "$STARTRED""Aborting script.  Remove these directories and run the script again""$ENDRED" >&2
    exit
fi

# If there are gdemu directories present in the destination derictory append
# underscore to their names.
TARGET_DIRS=`find $TARGET_DIR -regextype sed -regex "$TARGET_DIR/*[0-9][0-9]*"`
if [[ ! -z $TARGET_DIRS ]]; then
    echo "Renaming target directories to avoid name clashes"
    for EXISTING_TARGET_DIR in $TARGET_DIRS; do
        echo "Renaming $EXISTING_TARGET_DIR to $EXISTING_TARGET_DIR""_"
        mv "$EXISTING_TARGET_DIR" "$EXISTING_TARGET_DIR"_
    done
    # Treat gdmenu directory specialy
    if [[ -d "$TARGET_DIR/01_" ]]; then
        mv "$TARGET_DIR/01_" "$TARGET_DIR/gdmenu_old"
    fi
fi

# Initialize GDMenu ini file.
if [[ -e $GDMENU_INI ]]; then
    echo "$GDMENU_INI exists, backing up as ${GDMENU_INI}.bak"
    mv "$GDMENU_INI" "$GDMENU_INI"".bak"
fi
# Values here are hardcoded since we know what the ip.bin contains.  If ip.bin
# ever gets updated these lines need to be updated accordingly
echo "[GDMENU]"          >> $GDMENU_INI
echo "01.name=GDMenu"    >> $GDMENU_INI
echo "01.disc=1/1"       >> $GDMENU_INI
echo "01.vga=1"          >> $GDMENU_INI
echo "01.region=JUE"     >> $GDMENU_INI
echo "01.version=V0.6.0" >> $GDMENU_INI
echo "01.date=20160812"  >> $GDMENU_INI
echo ""                  >> $GDMENU_INI

# Initialize output game list file.
if [[ -e $OUTPUT_FILE ]]; then
    echo "$OUTPUT_FILE exists, backing up as ${OUTPUT_FILE}.bak"
    mv "$OUTPUT_FILE" "$OUTPUT_FILE"".bak"
fi


# Directory 01 reserved for GDMenu, start game directories with 02
INDEX=2

while read GAME; do
    echo "Processing game \"$GAME\""

    # Ensure that names of directories 1-9 start with a 0
    if [[ $INDEX -lt 10 ]]; then
        DIR_NAME=$(printf "%02d" $INDEX)
    else
        DIR_NAME="$INDEX"
    fi

    # Attempt to locate the game subdirectory in the target directory.  If it's
    # already there just restore the game by renaming the temporary directory,
    # don't attempt to extract the game from an archive
    GAME_FOUND=false
    for EXISTING_GAME_DIR in `find $TARGET_DIR -regextype sed -regex "$TARGET_DIR/*[0-9][0-9]*_"`; do
        if [[ "$GAME" == "`cat $EXISTING_GAME_DIR/$ARCHIVE_FILE`" ]]; then
            echo "Game \"$GAME\" located in target directory, placing it in directory \"$DIR_NAME\""
            mv "$EXISTING_GAME_DIR" "$TARGET_DIR/$DIR_NAME"
            (( INDEX++ ))
            echo "$GAME" >> "$OUTPUT_FILE"
            GAME_FOUND=true
            break # if game found don't iterate over remaining directories
        fi
    done

    # If game not found in target directory extract it from a zip archive
    if [[ $GAME_FOUND == false ]]; then
        GAME_ARCHIVE="$SOURCE_DIR/$GAME"
        GAME_TARGET_DIR="$TARGET_DIR/$DIR_NAME"

        # Missing archives are not considered fatal, just skip the game
        if [[ ! -f "$GAME_ARCHIVE" ]]; then
            echo -e "$STARTRED""Game archive not found: \"$GAME_ARCHIVE\", skipping""$ENDRED"
            break
        fi

        echo "Extracting archive $GAME_ARCHIVE"
        unzip "$GAME_ARCHIVE" -d "$DIR_NAME"

        # Extracting errors are fatal - maybe we have no space left on the
        # device?  Abort the script instead of wreaking havoc
        if [[ $? -ne 0 ]]; then
            echo -e "$STARTRED""Error extracting archive: $GAME_ARCHIVE""$ENDRED" >&2
            echo -e "$STARTRED""Aborting script""$ENDRED" >&2
            exit;
        fi

        # Determine whether we are dealing with GDI or CDI image.
        DISC_FILE=`find "$DIR_NAME" -type f -name *.gdi | head -n 1`
        if [[ ! -z $DISC_FILE ]]; then
            TYPE="gdi"
        else
            DISC_FILE=`find "$DIR_NAME" -type f -name *.cdi | head -n 1`
            TYPE="cdi"
        fi

        # If we didn't find a GDI or CDI image inside the extracted archive we
        # skip it.  This isn't perfect since the error message might get lost in
        # the output noise, leading to perception that everything went fine when
        # it actually didn't.  But aborting the script in the middle of
        # execution can potentially cause mess so skipping seems like a better
        # solution.
        if [[ -z $DISC_FILE ]]; then
            echo -e "$STARTRED""Couldn't find any GDI or CDI file in $GAME_ARCHIVE""$ENDRED" >&2
            echo -e "$STARTRED""Skipping""$ENDRED" >&2
            break
        fi

        DISC_FILE=`basename "$DISC_FILE"`
        # Rename the gdi/cdi file to disc.gdi/disc.cdi, move the extracted game
        # to target directory, add the game to the game list
        echo "Generating $ARCHIVE_FILE"
        echo "$GAME" > "$DIR_NAME/$ARCHIVE_FILE"
        echo "Renaming disc file \"$DISC_FILE\" to \"disc.$TYPE\""
        # If moving files goes wrong abort immediately
        mv "$DIR_NAME/$DISC_FILE" "$DIR_NAME/disc.$TYPE" || exit
        echo "Moving game to target directory"
        mv "$DIR_NAME" "$TARGET_DIR" || exit
        (( INDEX++ ))
        echo "Adding \"$GAME\" to $OUTPUT_FILE"
        echo "Game \"$GAME\" has been placed in directory \"$DIR_NAME\""
        echo "$GAME" >> "$OUTPUT_FILE"
    fi

    # Now that the image files are in the target directory we need to extract
    # information required to create a GDMenu entry for the game.  For GDI files
    # this information is stored in an ip.bin file inside a GDI image.  See
    # https://mc.pp.se/dc/ip0000.bin.html for more information.  For CDI files
    # this information is stored in first 16 sectors of the last data track.  To
    # read this information we need to extract the CDI file to a /tmp directory
    # in order to get access to data tracks.
    if [[ $TYPE == "gdi" ]]; then
        ./tools/gditools.py -i "$TARGET_DIR/$DIR_NAME/disc.gdi" -b ip.bin
        METADATA_FILE="$TARGET_DIR/$DIR_NAME/ip.bin"
    else
        TMP_DIR=`mktemp -d -t dc-card-maker-XXXXX`
        ./tools/cdirip "$TARGET_DIR/$DIR_NAME/disc.cdi" $TMP_DIR
        # Note: this is potentially fragile
        METADATA_FILE=`find $TMP_DIR -type f -name *.iso | sort | tail -n 1`
    fi

    # Get the metadata
    if [[ -e "$TARGET_DIR/$DIR_NAME/$NAME_FILE" ]]; then
        NAME_INFO=`cat $TARGET_DIR/$DIR_NAME/$NAME_FILE | head -n 1`
    else
        NAME_INFO=`hexdump -v -e '"%c"' -s0x80 -n 128 $METADATA_FILE | sed 's/^[[:blank:]]*//;s/[[:blank:]]*$//'`
        echo "$NAME_INFO" > "$TARGET_DIR/$DIR_NAME/$NAME_FILE"
    fi
    DISC_INFO=`hexdump -v -e '"%c"' -s0x2B -n 3 $METADATA_FILE`
    VGA_INFO=`hexdump -v -e '"%c"' -s0x3D -n 1 $METADATA_FILE`
    REGION_INFO=`hexdump -v -e '"%c"' -s0x30 -n 8 $METADATA_FILE | sed 's/[[:blank:]]*//g'`
    VERSION_INFO=`hexdump -v -e '"%c"' -s0x4A -n 6 $METADATA_FILE`
    DATE_INFO=`hexdump -v -e '"%c"' -s0x50 -n 8 $METADATA_FILE`

    # Remove metadata files
    rm "$METADATA_FILE"
    if [[ $TYPE == "cdi" ]]; then
        rm -rf $TMP_DIR
    fi

    # Write menu entry data to INI file
    echo "$DIR_NAME.name=$NAME_INFO"       >> $GDMENU_INI
    echo "$DIR_NAME.disc=$DISC_INFO"       >> $GDMENU_INI
    echo "$DIR_NAME.vga=$VGA_INFO"         >> $GDMENU_INI
    echo "$DIR_NAME.region=$REGION_INFO"   >> $GDMENU_INI
    echo "$DIR_NAME.version=$VERSION_INFO" >> $GDMENU_INI
    echo "$DIR_NAME.date=$DATE_INFO"       >> $GDMENU_INI
    echo ""                                >> $GDMENU_INI

done < "$INPUT_FILE"

# Build GDMenu cdi image and put it in 01 directory
genisoimage -C 0,11702 -V GDMENU -G data/ip.bin -r -J -l -input-charset iso8859-1 -o gdmenu.iso data/1ST_READ.BIN $GDMENU_INI
./tools/cdi4dc gdmenu.iso gdmenu.cdi
rm gdmenu.iso
mkdir "$TARGET_DIR/01"
mv gdmenu.cdi "$TARGET_DIR/01"

# Copy default GDMenu configuration
cp ini/GDEMU.ini "$TARGET_DIR"

# Restore backup copy of GDMenu
if [[ -d "$TARGET_DIR/gdmenu_old" ]]; then
    mv "$TARGET_DIR/gdmenu_old" "$TARGET_DIR/01_"
fi

# Report any leftover dirs to the user.  Re-running the script won't be possible
# if these exist.
LEFTOVER_DIRS=`find $TARGET_DIR -regextype sed -regex "$TARGET_DIR/*[0-9][0-9]*_"`
if [[ ! -z $LEFTOVER_DIRS ]]; then
    echo -e "$STARTRED""Following directories at target directory contain old games""$ENDRED"
    for DIR in $LEFTOVER_DIRS; do
        echo -e "$STARTRED"$DIR"$ENDRED"
    done
    echo -e "$STARTRED""Delete or move them to a different location.""$ENDRED"
fi
