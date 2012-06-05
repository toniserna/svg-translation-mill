#!/bin/bash
#
# Usage:
#     svg2po.sh SVG_FILE
#
# Licensed under: GPLv3 (full text at LICENSE.md)
#
# Author: Toni Serna <serna.toni@gmail.com>
#
# Version/Date(YYYY-MM-DD): 1.0/2012-06-03
#
# Dependencies: pcregrep, po2svg.sh
#
# Recommended: inkscape
#
# Optional: virtaal
#
# Description:
#     Extracts the literal texts included in <text> ... </text> blocks from SVG_FILE.
# The result is sored in a file called SVG_FILE.po in the following format for each text block:
#
#     <blank line>
#     msgid "Literal text"
#     msgstr "-"
#
# In SVG format a multiline text bolck is split in multiple <tspan>text</tspan> blocks, one per line.
# This script concatenates in a single string all the <tspan>text</tspan> blocks in any <text> .. </text> blocks.
#
# Changelog (YYYY-MM-DD[:Version]):
# 
#     2012-06-03:1.0
#         First release
#

#----------------------------------------------------------
# Input SVG_FILE validation tests
SVG_FILE=$1

[ ! "$SVG_FILE" ] && echo -e "ERROR. Missing SVG_FILE\nUsage:\n    svg2po.sh SVG_FILE" >&2 && exit 1
if ! file -b "$SVG_FILE" | grep SVG >/dev/null
then
    echo -e "ERROR. This script is only able to process\nSVG (Scalable Vector Graphic) files" >&2
    exit 2
fi

# The hard core
sed -E -n '1h;1!H;${;g;s/<tspan[^>]*>/ /g;p;}' "$SVG_FILE" | sed 's/<\/tspan>//g' | pcregrep -Mo '<text[^>]*>.*<\/text>' | sed -E -n '1h;1!H;${;g;s/<text[^>]*> /\nmsgid "/g;p;}' | sed 's/<\/text>/"\nmsgstr "-"/' > "$SVG_FILE".po
#
# Regular expressions and chain of operations explained:
#
# 1. First "sed": It is able to operate with multiline regular expressions.
#    It searches all the <tspan [something]> tags and replaces them with a blank space.
# 2. Second "sed": In a multiline enabled expression it deletes all the </tspan> tags from the file.
#    At this point the different lines of every text box are put toghether at the same line with
#    an extra blank space at the beginning and a blank between every line.
# 3. pcregrep: It is a multiline-enabled version of the normal "grep", it returns only the parts of
#    the file that match the form: <text [something]>[Literal text]</text>
#    At this point we get only the part of the svg file in the form: <text [something]>Literal texts</tspan>
# 4. Third "sed": Another multiline expression to get rid of all the "<text [something]> " tags and
#    replace them for [newline]nmsgid ".
# 5. Fourth "sed": This removes the </text> tags and replaces them with a closing <">[newline]msgstr "-"
# 6. The result of this chain of transformations is stored in a file called SVG_FILE.po
#
NumMSGID=`cat "$SVG_FILE".po | wc -l`
NumMSGID=$[ $NumMSGID / 3 ] # We have 3 lines per text

[ $NumMSGID -eq 0 ] && "ERROR. No texts found in this file\nRemember that curves or bitmaps will not be processed" >&2 && rm "$SVG_FILE.po" && exit 3

clear
echo -e "Text extraction finished: $NumMSGID texts found.\nA file $SVG_FILE.po has been generated\n" >&2
echo -en "Would you like to start translating it now?\n(Your default editor will be opened)\n[y/n] " >&2
read -n1 ANSWER
echo

if [ $ANSWER == 'y' -o $ANSWER == 'Y' ]
then
    ${VISUAL:-${FCEDIT:-${EDITOR:-vi}}} "$SVG_FILE".po
else
    exit 0
fi

NumMSGSTR=`grep -c '^msgstr \"..\+\"' "$SVG_FILE".po`
if [ $NumMSGSTR -eq $NumMSGID ]
then
    clear
    echo -en "Finished translating?\n(If finished the new texts will be integrated in a new SVG file)\n[y/n] ">&2
    read -n1 ANSWER
    echo

    if [ $ANSWER == 'y' -o $ANSWER == 'Y' ]
    then
        #If svg-translation-mill is installed in a directory in the PATH,
        #the following call must not be preceeded by ./
        ./po2svg.sh "$SVG_FILE"
    else
        echo -e "When translation is ready remember to execute:\n    po2svg.sh $SVG_FILE" >&2
        exit 0
    fi
fi
