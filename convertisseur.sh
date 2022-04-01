#!/bin/bash

set -o errexit # Exit if command failed.
set -o pipefail # Exit if pipe failed.
set -o nounset # Exit if variable not set.

# Remove the initial space and instead use '\n'.
IFS=$'\n\t'

# MIT LICENSE
# AUTHORS: Enzo Mourany

if [[ -d "src" ]]
then 
	rm -r src
fi

mkdir src
echo "<!DOCTYPE html>
<html>
<head>
        <meta charset="utf-8">
        <title>TITLE</title>
</head>
<body bgcolor="yellow">
        <h1>TITLE</h1>
        <img width="100%" src="PDFIMAGE">
        <br/>
        <audio controls>
                <source src="AUDIOOGG" type="audio/ogg">
                <source src="AUDIOMP3" type="audio/mpeg">
                Your browser does not support the audio element.
        </audio>
        <a href="LASTPAGE">precedant</a>
        <a href="NEXTPAGE">suivant</a>
</body>
</html>" > "src/template.html"

echo "<!DOCTYPE html>
<html>
<head>
        <meta charset="utf-8">
        <title>HOME</title>
</head>
<body bgcolor="yellow">
        <h1> Home page </h1>
        SUMM
</body>
</html>" > "src/templateHome.html"


# SYNOPSIS
# 	checkHelpFlag helpOpt
#
# DESCRIPTION
#	Verifies that the helpOpt is "-h" and displays the help + exits if so.
#
# EXAMPLE
#	checkHelpFlag -h
#
function checkHelpFlag
{
	if [ $1 == "-h" ]
	then
        	echo "./convertisseur.sh -f <source> -t <destination> [-s]"
        	echo "./convertisseur.sh -h"
        	echo "	-f <source> permet de specifier le storyboard"
        	echo "	-t <destination> permet de specifier le dossier de destination"
        	echo "	-s indique que nous souhaitons ouvrir la 1ere page dans le navigateur par defaut de l'utilisateur"
        	echo "	-h affiche l'aide d'utilisation"
		exit 0
	fi
}

checkHelpFlag $1

# SYNOPSIS
# 	checkFileFlag fileOpt fileName
#
# DESCRIPTION
#	Verifies that the fileOpt is "-f" and proceeds to nullCheck fileName.
#
# EXAMPLE
#	checkFileFlag -f storyboard.txt
#
function checkFileFlag
{
	if [ $1 == "-f" ] 
	then
  		echo "[debug] -f is used."
		if [ -z "$2" ]
		then
			echo "file arg cannot be empty">&2
			exit 2
		else
	  		if test -f $2
	  		then
	  			echo "[debug] $2 found."
	  		else
				echo "can't find $2">&2
		  		exit 2
	  		fi
  		fi
	else
		echo "First arg invalid, -h for help"
		exit 2
	fi
}

checkFileFlag $1 $2


# SYNOPSIS
# 	createSoundFile src dst start end
#
# DESCRIPTION
#	Creates a dst.ogg soundFile from trimming a src.amr sound file from start timeStamp to end timeStamp.
#
# EXAMPLE
#	createSoundFile audio.amr audio.ogg 0 1
#
function createSoundFile
{
	sox "$1" "$2.ogg" trim "$3" "$4"
	#ffmpeg -i "${2}.ogg" "${2}.mp3"
	sleep 0.1
}


# SYNOPSIS
# 	createPngFromPdf pdfName pageNb imageName
#
# DESCRIPTION
# 	Creates a png imageName.png of the page number pageNb from pdfName.pdf.
#
# EXAMPLE
#	createPngFromPdf pdfName.pdf 1 page1.png
#
function createPngFromPdf
{
	pdftoppm -png $1 -f $2 -l $2 > $3
}


# SYNOPSIS
# 	createHtmlPage pageNb title image audioogg audimp3 last next
#
# DESCRIPTION
# 	Creates an HTML page in DIRECTORY by replacing the provided variables in the template.html.
#
# EXAMPLE
#	createHtmlPafe 1 Un page1.png page1.ogg page1.mp3 0 2
#
function createHtmlPage
{
	cp ./src/template.html "$DIRECTORY/page$1.html"
	cd $DIRECTORY	
	#sed -i 's/search_string/replace_string/' "page$1.html"

	sed -i "s/TITLE/$2/" "page$1.html"
	sed -i "s/PDFIMAGE/$3/" "page$1.html"
	sed -i "s/AUDIOOGG/$4/" "page$1.html"
	sed -i "s/AUDIOMP3/$5/" "page$1.html"
	sed -i "s/LASTPAGE/page$6.html/" "page$1.html"
	sed -i "s/NEXTPAGE/page$7.html/" "page$1.html"
	cd ..
}

# SYNOPSIS
# 	processStoryboardFile storyboardFile
#
# DESCRIPTION
# 	Creates all the html pages in the $DIRECTORY according to the storyboardFile.
#
# EXAMPLE
#       processStoryboardFile storyboard.txt
#
function processStoryboardFile
{
	pageMax=$(cat $1 | wc -l)
	cp ./src/templateHome.html "$DIRECTORY/"
	mv "$DIRECTORY/templateHome.html" "$DIRECTORY/pagehome.html"
	
	while read p; do
  		#echo "$p"
		title=$(echo $p | cut -d "," -f1)
		pdfName=$(echo $p | cut -d "," -f2)
		page=$(echo $p | cut -d "," -f3)
		src=$(echo $p | cut -d "," -f4)
		start_=$(echo $p | cut -d "," -f5)
		end=$(echo $p | cut -d "," -f6)

		createPngFromPdf $pdfName $page "$DIRECTORY/images/page${page}.png"	
		createSoundFile $src "$DIRECTORY/audio/page${page}" $start_ $end
		sed -i "s/SUMM/		<a href=\"page$page.html\">to page $page<\/a><br>\n		SUMM/" "$DIRECTORY/pagehome.html"	
		if [ "$page" != "$pageMax" ]
		then
			if [[ "$page" == "1" ]]
			then
				createHtmlPage $page $title "images\/page${page}.png" "audio\/page${page}.ogg" "audio\/page${page}.mp3" "home" $(($page+1))
			else
				createHtmlPage $page $title "images\/page${page}.png" "audio\/page${page}.ogg" "audio\/page${page}.mp3" $(($page-1)) $(($page+1))
			fi
		else
			createHtmlPage $page $title "images\/page${page}.png" "audio\/page${page}.ogg" "audio\/page${page}.mp3" $(($page-1)) "home"
		fi
	done <$1
	sed -i "s/SUMM//" "$DIRECTORY/pagehome.html"
}

DIRECTORY=pages
if [ "$#" == "3" ] || [ "$#" == "4" ]; then
    if [ "$3" == "-t" ]; then
	    if [ -z "$4" ]
            then
                echo "-t arg cannot be empty">&2
            	exit 2
	    fi
	    DIRECTORY=$4
    fi
else
        if [ "$#" == "5" ]; then
            if [ "$3" == "-t" ]; then
                DIRECTORY=$4
	    else
		    echo "3rd arg invalid, $# args total"
		    exit 2
            fi
        fi
fi


if [[ -d "$DIRECTORY" ]]
then
    echo "$DIRECTORY dir alr exists in current dir, do you want to delete it ? Y/n"

    read ans

    if [[ "$ans" != "Y" ]]
    then
	    echo "exiting .."
	    exit 2
    fi

    rm -r $DIRECTORY
fi

mkdir -p $DIRECTORY/images
mkdir -p $DIRECTORY/audio

processStoryboardFile $2
rm -r src


# SYNOPSIS
# 	checkSFlag arg
# 
# DESCRIPTION
#	Checks if the arg provided is -s and if so, launches the first page in firefox.
#
# EXAMPLE
#       checkSFlag $3
#
function checkSFlag
{
        if [ $1 == "-s" ]
        then
                firefox ./$DIRECTORY/pagehome.html &
                exit 0
        fi
}

if [ "$#" == "3" ] 
then
    checkSFlag $3
else
	if [ "$#" == "5" ] 
	then
		checkSFlag $5
	fi
fi

