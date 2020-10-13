#!/bin/bash

# Usage:
#
#   dc-card-maker.sh game_list.txt source_dir target_dir
#
# See README.md for detailed instructions
#
# (c) Jan Stolarek 2020, GPL3 License

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
GDMENU_INI=LIST.INI
NAME_FILE=archive.txt
# For error printing in red
STARTRED="\e[31m"
ENDCOLOR="\e[0m"

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
    echo -e "$STARTRED""Following directories from previous session found:""$ENDRED"
    for DIR in $LEFTOVER_DIRS; do
        echo "$DIR"
    done
    echo -e "$STARTRED""Aborting script.  Remove these directories and run the script again""$ENDRED"
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
echo "[GDMENU]"          >> $GDMENU_INI
echo "01.name=GDMENU"    >> $GDMENU_INI
echo "01.disc=1/1"       >> $GDMENU_INI
echo "01.vga=1"          >> $GDMENU_INI # differs from ip.bin !
echo "01.region=JUE"     >> $GDMENU_INI
echo "01.version=V0.6.0" >> $GDMENU_INI
echo "01.date=20160812"  >> $GDMENU_INI
echo ""                  >> $GDMENU_INI

# Directory 01 reserved for GDMenu, start with 02
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
    # already there just restory, don't attempt to extract it from an archive
    GAME_FOUND=false
    for EXISTING_GAME_DIR in `find $TARGET_DIR -regextype sed -regex "$TARGET_DIR/*[0-9][0-9]*_"`; do
        if [[ "$GAME" == "`cat $EXISTING_GAME_DIR/$NAME_FILE`" ]]; then
            echo "Game \"$GAME\" located in target directory, placing it in directory \"$DIR_NAME\""
            mv "$EXISTING_GAME_DIR" "$TARGET_DIR/$DIR_NAME"
            (( INDEX++ ))
            echo "$GAME" >> "$OUTPUT_FILE"
            GAME_FOUND=true
            break # if found don't iterate over remaining directories
        fi
    done

    # If game not found on card extract it from zip archive
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

        # Extracting errors are fatal - stop the script
        if [[ $? -ne 0 ]]; then
            echo -e "$STARTRED""Error extracting archive: $GAME_ARCHIVE""$ENDRED"
            echo -e "$STARTRED""Aborting script""$ENDRED"
            exit;
        fi

        echo "Generating $NAME_FILE"
        echo "$GAME" > "$DIR_NAME/$NAME_FILE"
        GDI_FILE=`find "$DIR_NAME" -type f -name *.gdi | head -n 1`
        GDI_FILE=`basename "$GDI_FILE"`
        echo "Renaming GDI file \"$GDI_FILE\" to \"disc.gdi\""
        mv "$DIR_NAME/$GDI_FILE" "$DIR_NAME/disc.gdi"
        echo "Moving game to target directory"
        mv "$DIR_NAME" "$TARGET_DIR"
        (( INDEX++ ))
        echo "Adding \"$GAME\" to game_list.txt"
        echo "Game \"$GAME\" has been placed in directory \"$DIR_NAME\""
        echo "$GAME" >> "$OUTPUT_FILE"
    fi

    # Now that the image files are in the target directory let's create a
    # GDMenu.  Necessary information is taken from ip.bin file extracted from
    # the gdi image
    ./gditools.py -i "$TARGET_DIR/$DIR_NAME/disc.gdi" -b ip.bin
    NAME_INFO=`hexdump -v -e '"%c"' -s0x80 -n 128 $TARGET_DIR/$DIR_NAME/ip.bin | sed 's/^[[:blank:]]*//;s/[[:blank:]]*$//'`
    DISC_INFO=`hexdump -v -e '"%c"' -s0x2B -n 3 $TARGET_DIR/$DIR_NAME/ip.bin`
    VGA_INFO=`hexdump -v -e '"%c"' -s0x3E -n 1 $TARGET_DIR/$DIR_NAME/ip.bin`
    REGION_INFO=`hexdump -v -e '"%c"' -s0x30 -n 8 $TARGET_DIR/$DIR_NAME/ip.bin | sed 's/[[:blank:]]*//g'`
    VERSION_INFO=`hexdump -v -e '"%c"' -s0x4A -n 6 $TARGET_DIR/$DIR_NAME/ip.bin`
    DATE_INFO=`hexdump -v -e '"%c"' -s0x50 -n 8 $TARGET_DIR/$DIR_NAME/ip.bin`
    rm $TARGET_DIR/$DIR_NAME/ip.bin

    echo "$DIR_NAME.name=$NAME_INFO"       >> $GDMENU_INI
    echo "$DIR_NAME.disc=$DISC_INFO"       >> $GDMENU_INI
    echo "$DIR_NAME.vga=$VGA_INFO"         >> $GDMENU_INI
    echo "$DIR_NAME.region=$REGION_INFO"   >> $GDMENU_INI
    echo "$DIR_NAME.version=$VERSION_INFO" >> $GDMENU_INI
    echo "$DIR_NAME.date=$DATE_INFO"       >> $GDMENU_INI
    echo ""                                >> $GDMENU_INI

done < "$INPUT_FILE"

# Build GDMenu cdi image and put it in 01 directory
genisoimage -C 0,11702 -V GDMENU -G ip.bin -r -J -l -input-charset iso8859-1 -o gdmenu.iso 1ST_READ.BIN $GDMENU_INI
mkdir "$TARGET_DIR/01"
mv gdmenu.iso "$TARGET_DIR/01"

# Copy default GDMenu configuration
cp GDEMU.ini "$TARGET_DIR"

# Report any leftover dirs to the user.  Re-running the script won't be possible
# if these exist.
LEFTOVER_DIRS=`find $TARGET_DIR -regextype sed -regex "$TARGET_DIR/*[0-9][0-9]*_"`
if [[ ! -z $LEFTOVER_DIRS ]]; then
    echo -e "$STARTRED""Following directories at target directory contain old games""$ENDRED"
    for DIR in $LEFTOVER_DIRS; do
        echo $DIR
    done
    echo -e "$STARTRED""Consider deleting them""$ENDRED"
fi
