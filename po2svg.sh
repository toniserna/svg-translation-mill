#!/bin/bash
#
# Usage:
#     po2svg.sh SVG_FILE
#
# Licensed under: GPLv3 (full text at LICENSE.md)
#
# Author: Toni Serna <serna.toni@gmail.com>
#
# Version/Date(YYYY-MM-DD): 1.0/2012-06-03
#
# Dependencies: pcregrep
#
# Recommended: inkscape
#
# Optional: virtaal
#
# Description:
#     Integrates the texts translated at SVG_FILE.po back to SVG_FILE and generates a new version
# called SVG_FILE_translated.svg
#     SVG_FILE.po must have the following exact format for every string (as generated svg2po SVG_FILE):
#
#     <blank line>
#     msgid "Original string"
#     msgstr "Translated string"
#
#     In SVG format a multiline text bolck is split in multiple <tspan>text</tspan> blocks, one per line.
# This script integrates the translated strings as a one-line text block. Further manual editing required.
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

# The whole file text is stored into the FILE variable
FILE=`cat "$SVG_FILE"`

# The following chain of operations extracts the first line of every multiline text blocks
pcregrep -Mo '<text[^>]*>([^<]*<tspan[^>]*>[^<]*<\/tspan>)*([^<]*<tspan[^>]*>)*[^<]*<\/text>' $SVG_FILE| sed -E -n '1h;1!H;${;g;s/<text[^>]*>[^<]*<tspan[^>]*>([^<]*)<\/tspan>([^<]*<tspan[^>]*>[^<]*<\/tspan>)*([^<]*<tspan[^>]*>)*[^<]*<\/text>/\1/g;p;}' | sort > /tmp/tempfile.$$
#
# Regular expressions and chain of operations explained:
#
# 1. "pcregrep": It is able to operate with multiline regular expressions.
#    It reduces the FILE to the <text [something]>...</text> tags. In the middle of these two tags
# a series of one(0) or more <tspan [something]>One-line string</tspan> will be found.
#    Notice that before the final </text> sometimes I found a non closed <tspan [something]> tag.
#    In order to make this seach mor robust and fail-proof I expected extra characters (possibly blanks
# or tabs) before opening any <tag>.
# 2. "sed": It is a "remembering" and multiline-enabled regular expression. Following the same schema
# explained before it "remembers" only the first line of any multi-line text blocks:
# the subregexp between "(" and ")". Then it reduces the whole <text>...</text> blocks to this remembered
# string.
#    Important: all of this srtings must be unique and none of them must be a substring found at the
# beginning of any of the rest of strings. This may require careful designing of the texts.
# 3. These texts are alphabetically sorted and stored in a temporary file
#

clear
NumMSGID=`cat /tmp/tempfile.$$ | wc -l`

[ $NumMSGID -eq 0 ] && "ERROR. No texts found in this file\nRemember that curves or bitmaps will not be processed" >&2 && rm "$1.po" && exit 3

echo -e "$NumMSGID strings found\nWould you like to check these identifying strings?\n(Your default editor will be opened)\n\nThey must be unique and not included at the beginning of any other" >&2
echo -en "[y/n] " >&2
read -n1 ANSWER
echo

if [ $ANSWER == 'y' -o $ANSWER == 'Y' ]
then
    ${VISUAL:-${FCEDIT:-${EDITOR:-vi}}} /tmp/tempfile.$$
fi

# The identifying strings are read from tempfile one by one into MSGID
while read MSGID
do
    # To avoid the special meaning in regexps of / and *, they are prefixed with \
    MSGID=`echo "$MSGID" | sed 's:\/:\\\/:g' | sed 's/\*/\\\*/g'`
    # MSGSTR will store the proper translation of the sentence which starts with MSGID at SVG_FILE.po
    # It is caught by reading the following line to the one which starts as "msgid "Identifying sting
    # The formating extras like -msgstr - and two " are removed
    MSGSTR=`grep -A 1 "msgid \"$MSGID" "$SVG_FILE".po | tail -1 | sed 's/^msgstr "//' | sed 's/"$//'`
    # Again, to avoid the special meaning in regexps of / and * ...
    MSGSTR=`echo "$MSGSTR" | sed 's:\/:\\\/:g' | sed 's/\*/\\\*/g'`

    # This performs the magic. In the entire text of the SVG_FILE it searches and replaces
    # Searches what?: the supposedly only <tspan></tspan> block which has the MSGID string
    # Replaced by what?: The whole translation for the text block as the first <tspan></tspan> block
    # at the corresponding <text></text>
    # And what about the second multiline "sed": It keeps the whole <text> block and the first
    # <tspan>Translated string</tspan> the rest of <tspan></tspan> int the same <text> are removed.
    # Note that a (or more) possible not closed final <tspan> tags are taken in consideration.
    # Also, in order to respond to extra blanks or tabs before every tag, extra [^<]* subexpresions
    # are included
    FILE=`echo "$FILE" | sed "s/>$MSGID[^<]*<\/tspan>/>$MSGSTR<\/tspan>/" | sed -E -n '1h;1!H;${;g;s/(<text[^>]*>[^<]*<tspan[^>]*>[^<]*<\/tspan>)([^<]*<tspan[^>]*>[^<]*<\/tspan>)*([^<]*<tspan[^>]*>)*[^<]*<\/text>/\1<\/text>/g;p;}'`

done < /tmp/tempfile.$$ # Every read whithin this loop will read from a line from the file

# The final result is flushed from memory to $SVG_FILE_translated.svg
echo "$FILE" > "${SVG_FILE}_translated.svg"
