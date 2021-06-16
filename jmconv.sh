#!/bin/bash
#
#Author : jamesjsakala@gmail.com
#Purpose: BASH CLI Script and front end to FFMPEG to convert playlist or file to other format
#Version: 0.001
#Date   : 13 Feb 2016
#
#
##Include Personal Config File
.  ~/.bin/jmconv/.config

help_msg(){
	echo "Usage : "`$BASENAMECMD $0`' -l [Playlistfile]'
	echo "      : "`$BASENAMECMD $0`'  [FIleToConvert]'
	echo 'Hint  : Permission to given file maybe denied'
	echo "        Bye!"
	exit 1
}
get_mediainfo_tags(){
	ARTIST0=`$MEDIAINFOBIN --Output="General;%Performer%"  "$INPUTFILE" ` 1>/dev/null  2>/dev/null
	TITLE0=`$MEDIAINFOBIN --Output="General;%Track%"  "$INPUTFILE" ` 1>/dev/null  2>/dev/null
	ALBUM0=`$MEDIAINFOBIN --Output="General;%Album%"  "$INPUTFILE" ` 1>/dev/null  2>/dev/null
	GENRE0=`$MEDIAINFOBIN --Output="General;%Genre%"  "$INPUTFILE" ` 1>/dev/null  2>/dev/null
	HASCORVERART0=`$MEDIAINFOBIN --Output="General;%Cover%"  "$INPUTFILE" ` 1>/dev/null  2>/dev/null

	FFARTIST0=`$MEDIAINFOBIN --Output="General;%Performer%"  "$INPUTFILE" | sed -e 's|[[:punct:]]||g' -e 's|\W\+| |g' -e 's|\W|_|g' ` 1>/dev/null  2>/dev/null
	FFTITLE0=`$MEDIAINFOBIN --Output="General;%Track%"  "$INPUTFILE" | sed -e 's|[[:punct:]]||g' -e 's|\W\+| |g' -e 's|\W|_|g' ` 1>/dev/null  2>/dev/null
	FFALBUM0=`$MEDIAINFOBIN --Output="General;%Album%"  "$INPUTFILE" | sed -e 's|[[:punct:]]||g' -e 's|\W\+| |g' -e 's|\W|_|g'  ` 1>/dev/null  2>/dev/null
	FFGENRE0=`$MEDIAINFOBIN --Output="General;%Genre%"  "$INPUTFILE" | sed -e 's|[[:punct:]]||g' -e 's|\W\+| |g' -e 's|\W|_|g'  ` 1>/dev/null  2>/dev/null

	if [ -z "$ARTIST0" ];then
		FFARTIST0="Unknown_Artist"
	fi
	if [ -z "$TITLE0" ];then
		FFTITLE0="Unknown_Track"
	fi
	if [ -z "$GENRE0" ];then
		GENRE0="Unknown"
	fi
	if [ -z "$HASCORVERART0" ];then
		HASCORVERART0="No"
	fi
}

get_file_extention(){
	INPUTFILEXTENTION="${INPUTFILE##*.}"
	INPUTFILEXTENTIONUPPER="${INPUTFILEXTENTION^^}"
	OUTPUTFILEXTENTIONUPPER="${OUPUTFORMAT^^}"
}

tag_processor(){
	$ID3TAGGERBIN  -a"$ARTIST0" -s"$TITLE0" -A"$ALBUM0"  -g"$GENRE0"  -c"Converted With JMCONV"  "$OUTPUTFILENAME" >/dev/null 1>/dev/null 2>/dev/null
}

corver_art_processor(){
	echo -n '[Cover:'
	if [ "$HASCORVERART0" = 'Yes' ];then
        	#echo "Embeded Corver Art Found! We will Use It"
		THUMBSCOUNT=0
		COVERARTSTATUS="Embeded"
	        RANDOMNUM=`date +%s`
        	if [ -d "$TEMPTHUMBDIR" ];then
                	TEMPTHUMBDIR="${TEMPTHUMBDIR}/${RANDOMNUM}"
		else
        		$MKDIRBIN -p $TEMPTHUMBDIR  1>/dev/null  2>/dev/null
        	fi
        	$MKDIRBIN -p $TEMPTHUMBDIR  
        	$EYED3BIN --itunes --write-images="$TEMPTHUMBDIR" "$INPUTFILE" 1>/dev/null  2>/dev/null
        	LISTOFTHUMBS=`$FINDBIN "$TEMPTHUMBDIR" -type f`
		for i in $LISTOFTHUMBS
		do
       			THUMBSCOUNT=`$EXPRCMDBIN $THUMBSCOUNT + 1 `
		done
	else
		LISTOFTHUMBS=`$FINDBIN "$INPUTFILEDIR" -iname '*.png' -o -iname '*.bmp' -o -iname '*.jpg' -o -iname '*.jpeg'`
		THUMBSCOUNT=0
       		if [ -z "$LISTOFTHUMBS" ];then
       			##NO THUMBS FOUND!
			COVERARTSTATUS="None"
       		else
       			for i in $LISTOFTHUMBS
       			do
               			THUMBSCOUNT=`$EXPRCMDBIN $THUMBSCOUNT + 1 `
       			done
       			if [ $THUMBSCOUNT -gt 0 ];then
       				COVERARTSTATUS="Alt"
			else
       				COVERARTSTATUS="None"
			fi
       		fi
	fi

	if [ $THUMBSCOUNT -eq 1 ];then
		MAINCOVERART=${LISTOFTHUMBS}
		$EYED3BIN --itunes --add-image="$MAINCOVERART":FRONT_COVER  "$OUTPUTFILENAME" 1>/dev/null  2>/dev/null
	elif [ $THUMBSCOUNT -ne 1 ];then

		OLDIFS=$IFS  #SAVE IFS SO WE CAN HANDLE SPACES PROPERLY  
		IFS=$(echo -en "\n\b")   #CHANGE IFS SO WE CAN HANDLE SPACES PROPERLY
		MAINCOVERART=0
		for i in $LISTOFTHUMBS
		do
			if [ "$MAINCOVERART" = "0" ];then
				MAINCOVERART=$i
			elif [ "$i" != "$MAINCOVERART" ];then
				if [ `$STATBIN -c %s "$i"` -gt `$STATBIN -c %s ${MAINCOVERART}` ];then
					MAINCOVERART=$i
				fi
			fi
		done
		IFS=$OLDIFS #RESTORE IFS
		$EYED3BIN --add-image="$MAINCOVERART":FRONT_COVER  "$OUTPUTFILENAME" 1>/dev/null  2>/dev/null
	else
		MAINCOVERART=0
		COVERARTSTATUS="None"
	fi
	echo -n $COVERARTSTATUS']...'
	if [ "$HASCORVERART0" = 'Yes' ];then
		$RMCMDBIN  -rf  $TEMPTHUMBDIR 1>/dev/null  2>/dev/null
	fi
}



ffmpegconv(){
	get_file_extention
	ZEFILENAME="$FFARTIST0-$FFTITLE0.$OUPUTFORMAT"
	if [ -e "$OUTPUTDIR/$ZEFILENAME" ];then
		PREEXTENTIONPREFIX=_`date +%s`
	else
		PREEXTENTIONPREFIX=''
	fi
        echo -n 'Converting: ['"$ARTIST0"' - '"$TITLE0"']...'
	ZEFILENAME="$FFARTIST0-$FFTITLE0$PREEXTENTIONPREFIX.$OUPUTFORMAT"
	if [ "$INPUTFILEXTENTIONUPPER" = "$OUTPUTFILEXTENTIONUPPER" ];then
		$CPBIN  "$INPUTFILE"  "$OUTPUTDIR/$ZEFILENAME"
        	CPSTATUS=`echo "$?"`
		if [ $CPSTATUS = "0" ];then
			echo '[DONE]'
		else
			echo '[FAILED]'
		fi
	else
        	$FFMPEGBIN -i "$INPUTFILE"  -ac 1  "$OUTPUTDIR/$ZEFILENAME"   1>/dev/null  2>/dev/null
		OUTPUTFILENAME="$OUTPUTDIR/$ZEFILENAME"
        	FFMPEGERRSTATUS=`echo "$?"`
		if [ $FFMPEGERRSTATUS = "0" ];then
			if [ $OUPUTFORMAT = 'aac' ];then
				tag_processor
				corver_art_processor
			fi
			echo '[DONE]'
		else
			echo '[FAILED]'
		fi

	fi
}


######################SANDBOX##########################
if [ $# -eq 1 ];then #&& -r "$1"  ];then
	get_file_extention
	GIVENFILETYPE=`$FILEBIN  "$1" | $GREPCMDBIN -ic  'playlist'`
	if [ $GIVENFILETYPE  -eq 0 ];then
		INPUTFILE="$1"
		INPUTFILEDIR=`$DIRNAMEBIN "$INPUTFILE"`
		get_mediainfo_tags
		ffmpegconv
	else
		CURPLAYLIST=`less $1 | tr -d '\r'`
		OLDIFSX=$IFS  #SAVE IFS SO WE CAN HANDLE SPACES PROPERLY  
		IFS=$(echo -en "\n\b")   #CHANGE IFS SO WE CAN HANDLE SPACES PROPERLY
		for x in $CURPLAYLIST
		do
			if [ -e "$x" ];then
				INPUTFILE="$x"
				INPUTFILEDIR=`$DIRNAMEBIN "$INPUTFILE" `
				get_mediainfo_tags
				ffmpegconv
			fi
		done
		IFS=$OLDIFSX #RESTORE IFS

	fi
else
	help_msg
	exit
fi
#######################################################
