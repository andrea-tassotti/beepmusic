#!/bin/bash
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#    Copyrights 2016 Andrea Tassotti
#
#	 @date:
#	 @version: 1.0
#
declare -A note_value_durations
declare -A freqmap

LINUX_OUTPUT=true
legato=true

#
#
#
function usage()
{
	echo "score2beep (C)2016 Andrea Tassotti"
	echo "score2beep [-b|-l] [-t <tonefilename>] < file.score > beepmusic"
	echo
	echo WHERE
	echo "  -b FreeBSD mode"
	echo "  -l Linux mode"
	echo "  -t filename of precalculated tones"
	echo
}


#
# Linux:  millisecs
# FreeBSD: cents of seconds
#
# $1 - beats_per_measure
# $2 - note_value
# $3 - tempo
#
function calculate_time()
{

	## millisec
	note_value_duration=$( echo "scale=1; (60000 / $3 ) "| bc)

	# All note_value_duration 
	# note_value_duration_x = note_value * note_value_duration / note_value_x
	for note_value_x in 1 2 4 8 16 32 64 128
	do
		note_value_durations["1/${note_value_x}"]=$( echo "scale=4; $2 * $note_value_duration / $note_value_x" | bc)
	done

	return
}


#
# $1 - duration
# $2 - modifier
function do_modifier()
{
		case $2 in
		".")
			# 1/2 increment
			echo "scale=4; n=$1 + ($1 / 2); scale=1; n/1" | bc
			;;
		"..")
			# 1/4 increment
			echo "scale=4; n=$1 + ($1 / 4); scale=1; n/1" | bc
			;;
		"...")
			# 1/8 increment
			echo "scale=4; n=$1 + ($1 / 8); scale=1; n/1" | bc
			;;
		[234567])
			# gruppo irregolare (se $beats_per_measure dispari)
			echo "scale=4; n=$1 / $2; scale=1; n/1" | bc
			;;
		*)
			echo "scale=1; $1/1" | bc
			;;
		esac
}
		
# defaults
tempo=120
beats_per_measure=4
note_value=4
measure=1	# as score notation
calculated_measure=1	# from note duration sum: must be < $measure
tones_file=~/tones.dat 


# Preroll
calculate_time $beats_per_measure $note_value $tempo

#
# Main
#
OPTIND=1
while getopts blt:h opt
do
	case $opt in
	l)
		LINUX_OUTPUT=true
		;;
	b)
		LINUX_OUTPUT=false
		;;
	t)
		tones_file=$OPTARG
		;;
	h)
		usage
		;;
	*)
		usage
		;;
	esac
done
shift $( expr $OPTIND - 1 )

# Read Tones Map
if [ -f $tones_file ]; then
while read line
do
	if [[ $line =~ ^# ]]; then continue; fi
	freqmap[${line%=*}]=${line#*=}
done < $tones_file
else
	echo ERROR: missing tones.dat
	exit 2
fi

#
# Linux command line have no length limits
# so we can create single long command line
#

if [[ $LINUX_OUTPUT = "true" ]]
then
	echo -n "beep "
fi

lineno=0
IFS=:
while read op duration modifier
do
	lineno=$((lineno+1))
	# Comments
	if [[ $op =~ ^# ]]; then
		#echo DEBUG $op $duration $modifier >&2
		# Measure indicator
		if [[ $op =~ [0-9]+ ]]
		then
			measure=$(echo $op | tr -cd '[:digit:]' )
			if [ $(echo "$measure == $calculated_measure" | bc ) -eq 0 ]
			then
				echo WARNING: line: $lineno: measure indicator $measure mismatch $calculated_measure >&2
			fi
		fi
		# "Legato" mode (default)
		[[ $op =~ legato ]] && legato=true
		# "Staccato" mode
		[[ $op =~ staccato ]] && legato=false
		continue;
	fi

	# Empty lines
	if [ -z "$op" ]; then continue; fi

	# echo $lineno: $calculated_measure >&2

	# Operations
	case $op in
	tsig)
		timesignature=$duration
		beats_per_measure=${timesignature%/*}
		note_value=${timesignature#*/}
		calculate_time $beats_per_measure $note_value $tempo ;;
	tempo|bpm)
		tempo=$duration
		calculate_time $beats_per_measure $note_value $tempo ;;
	P)
		if [ $(( $duration % 2 )) -ne 0 ]; then
			echo ERROR: line: $lineno: illegal odd duration $duration >&2
			break
		fi

		calculated_measure=$(echo "scale=4; $calculated_measure + 1/$duration" | bc)
		# Pause
		duration=${note_value_durations["1/$duration"]}
		duration=$(do_modifier $duration $modifier)
		if [[ $LINUX_OUTPUT = "true" ]]
		then
			# Linux (miminum frequency = 1Hz)
			echo -n "-f 1 -l 0 -D $duration -n "
		else
			# FreeBSD (in cent sec)
			duration_in_cent=$(echo "scale=1; $duration / 10" | bc )
			echo "beep -p 0 $duration_in_cent"
		fi
		;;
	[A-G]*[[:digit:]])
		if [ $(( $duration % 2 )) -ne 0 ]; then
			echo ERROR: line: $lineno: illegal odd duration $duration >&2
			break
		fi

		calculated_measure=$(echo "scale=4; $calculated_measure + 1/$duration" | bc)
		# Note
		duration=${note_value_durations["1/$duration"]}
		duration=$(do_modifier $duration $modifier)
		humanizer=0	# TODO: staccato mode. sum to duration some  millisec
if [ -z "${freqmap[$op]}" ] 
then
	echo ERROR: line $lineno: no frequency for note $op >&2
	exit 4
fi
		if [[ $LINUX_OUTPUT = "true" ]]
		then
			echo -n "-f ${freqmap[$op]} -l $duration -D $humanizer -n "
		else
			# FreeBSD (in cent sec)
			duration_in_cent=$(echo "scale=1; $duration / 10" | bc )
			echo "beep -p ${freqmap[$op]} $duration_in_cent"
		fi
		;;
	*)
		echo ERROR: line $lineno: Bad operator >&2
		exit 7
		;;
	esac
done

[[ $LINUX_OUTPUT = "true" ]] && echo >&2
echo Processed $calculated_measure measure. >&2
