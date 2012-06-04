SVG-TRANSLATION-MILL
--------------------
by Toni Serna <serna.toni@gmail.com>

Licensed under: GPLv3

The scenario
------------

If you come across an interesting svg (Scalable Vector Graphics), be a mind map, an infographic, the time line of events of "Pulp Fiction" or whatever, you will probably find  interesting to have it translated into a different language.

Without any help the process will be necessarily done from an svg editor like Inkscape on a copy of the original diagram. You will have to manually edit all the text boxes one by one and translate all the strings directly on the graphic.

This scenario worsens significantly if you are going to manage multiple translated versions of a graphic and need to contact a translator in order to get the job done. First of all you will need that the translator has an svg-compatible editor installed, then he or she must know the basics of editing vector graphics with such tool and besides you will probably have to check the final appearance of the graphic because the translator may have altered its layout.

The proposed solution
---------------------

Svg-translation-mill is a set of two bash scripts (svg2po.sh & po2svg.sh) that allow automatically generate a "po-like" file from a .svg, translate that file with a plain text editor and finally merge it back also automatically generating a new translated version of the original svg.

Installation
------------
  # You'll need pcregrep, a multiline capable grep-like command
  
sudo apt-get install pcregrep

  # Change with cd to your preferred folder and download there svg2po.sh and po2svg.sh
  
wget https://github.com/toniserna/svg-translation-mill/blob/master/po2svg.sh https://github.com/toniserna/svg-translation-mill/blob/master/svg2po.sh

  # Mark these scripts as executable
  
chmod a+x svg2po.sh po2svg.sh

  # Work as described in the next section of this README

The new workflow
----------------

Let's supose that you are the author of the svg file. Do not forget to install pcregrep (a multiline-enabled grep-like command): sudo apt-get install pcregrep (in GNU-Linux systems with the debian packaging system).

  1.  You will compose your graphic (let's name it SVG_FILE) using Inkscape or any other editor.  If any translation is needed, it includes different texts in your language of reference. If you are interested in facilitating contacting different translators consider to develop it at least an English version. When designing, keep texts as texts, do not convert them into paths or curves. It may be also interesting to export a bitmap version (.png, .jpg, .tiff etc.) of your SVG_FILE.

  2. From the command line and in the same folder wher you downloaded the two scripts, launch the first part of this mill:

     ./svg2po.sh SVG_FILE

   This will produce a file called a SVG_FILE.po (same folder of the original file). This file contains all the strings from the text boxes in your SVG_FILE in a format like this:

	msgid "Original text string 1"

	msgstr "-"


	msgid "Original text string 2"

	msgstr "-"


	msgid "Original text string 3"

	msgstr "-"

	...

  3. Send your translator the bitmap version of your SVG_FILE along with SVG_FILE.po

  4. Looking at the bitmap, the translator will be able to edit the SVG_FILE.po with any text editor. Other .po translation tools may be used (for example Virtaal) althoug some of them break the appropriate format of the file. An ordinay plain text editor will do the job.

  5. The translator just needs to send you back the SVG_FILE.po that must include all the translations. A translated file will look like this:

	msgid "Original text string 1"

	msgstr "Translated text string 1"


	msgid "Original text string 2"

	msgstr "Translated text string 2"


	msgid "Original text string 3"

	msgstr "Translated text string 3"

	...

  6. Time to start the second set of gears of this mill:

     ./po2svg.sh SVG_FILE

     After that you will get a file called SVG_FILE_translated.svg in the same folder of the original one.

  7. Open your new SVG_FILE_translated.svg with your Inkscape. You will have to manually adjust the line breaks in every text box and rearrange the position of the text boxes. This is because the SVG format splits every line of a text box in a different block <tspan>A line of text</tspan> every one placed automatically at its own coordinates. Once translated the lenght of strings may be completely different from original and thus is nearly impossible to automatically split the translated text into different lines. It has to be done manually.

  8. You are done.

Drawing for translation hints
-----------------------------
  * When designing an SVG graphic which has to be translated into several languages, try to keep every sentence which should be translated in the same text box.

  * Do not mix in the same text box different sentences.

Known limitations
-----------------
 * KL1: When using multiline text boxes, the first line of every text box in the graphic should be unique, as it is going to double as message identifier. In fact they do not only need to be unique, if one of the firsts strings of any text block is included as a starting substring of the first line of another text box, the po2svg.sh script won't be able to integrate the translations properly.

As an example of a problematic situation, imagine that in your svg you have a text box with the following two lines:

     NO
    ENTRY

You will have a problem if you have another text box like this:

    NO WAY OUT

Because "NO" (first text box) is a starting substring of "NO WAY OUT", po2svg.sh will use "NO" and "NO WAY OUT" as identificating strings.

It is free software
-------------------
Please feel free to use, study, comment, suggest, improve and share as you want as it is Free Software n the terms defined by GPLv3. Please keep me informed and credited.

No Freedom no Fun.
