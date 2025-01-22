#!/usr/bin/env bash

# TODO: Add support for other image formats

# Check for 2 arguments
if [ "$#" != 2 ]; then
    echo "Usage: bash $0 <year:month:day hour:minute:second>"
    exit 1
fi

IFS=: read -r year month day <<< "$1"

IFS=: read -r hour minute second <<< "$2"

months=(31 28 31 30 31 30 31 31 30 31 30 31)

# Leap year logic
leapYear=0
if (( $[year%4] == 0 )); then
	leapYear=1
	if (( $[year%100] == 0 && $[year%400] != 0 )); then
		leapYear=0
	fi
fi

if (( $leapYear )); then
	months[1]=29
fi

# Strip leading zeroes so values are interpreted as decimal (and not octal)
month=${month#0}
day=${day#0}
hour=${hour#0}
minute=${minute#0}
second=${second#0}

# Input validation
if (( month<1 || month>12 )); then
	echo "Enter a valid month value (between 1 and 12 inclusive)."
	exit
fi

if (( day<1 || day>months[$[month-1]] )); then
	echo "Enter a valid number of days for the month."
	exit
fi

if (( hour>23 )); then
	echo "Enter a valid hour value (between 0 and 23 inclusive)."
	exit
fi

if (( minute>59 )); then
	echo "Enter a valid minute value (between 0 and 60 inclusive)."
	exit
fi

if (( second>59 )); then
	echo "Enter a valid second value (between 0 and 59 inclusive)."
	exit
fi

# Updates time so that minutes run into hours, into days and so on correctly i.e., there won't be a 60th second, 60th minute, 24th hour, incorrect
# number of days in a month, nor a 12th month in any time. As an example, neither '2020:10:21 13:60:14' nor '2022:03:32 19:31:43' will be passed to 
# exiftool as there aren't 60 minutes in an hour nor does March have 32 days
updateTime(){
	if (( minute<60 )); then
		return
	fi

	minute=0
	((hour++))

	if (( hour<24 )); then
		return
	fi

	hour=0
	((day++))

	if (( day<=months[$[month-1]] )); then
		return
	fi

	day=1
	((month++))

	if (( month<12 )); then
		return
	fi

	month=1
	((year++))

	return
}

# Make backup directory in which to place original photos
if [ ! -d "./BACKUP/" ]; then
	mkdir BACKUP/
	cp *.jpg *.png BACKUP/
else
	echo "BACKUP/ directory already exists. Please move, rename or delete this directory so original photos won't be lost."
	exit
fi

for photo in $(ls *.jpg *.png);
do
	exiftool -d "%Y:%m:%d %H:%M:%S" -AllDates="$year':'$month':'$day' '$hour':'$minute':'$second" $photo

	randInt=$[($RANDOM%10)+5]

	if (( (second+randInt)>=60 )); then
		((minute++))
		updateTime
	fi

	second=$[second+randInt]
	second=$[second%60]
done

rm *_original
