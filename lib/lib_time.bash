#
# NAME
#
#	lib_time - a bash functions library
#
# SYNOPSIS
#
#	source lib_time.bash [--help]
#
# DESCRIPTION
#
#	This library provides functions for time calculations:
#		time_add            - add a time span  to a given date
#		time_addYears       - add some years   to a given date
#		time_addMonths      - add some months  to a given date
#		time_addDays        - add some days    to a given date
#		time_addHours       - add some hours   to a given date
#		time_addMinutes     - add some minutes to a given date
#		time_addSeconds     - add some seconds to a given date
#		time_compare        - compare two dates
#		time_convert        - convert time string from one format into another
#		time_diff           - difference between two dates
#		time_getMonth       - get month of year from a month's name or from a time-stamp
#		time_getMonthName   - get the month's name from a month of year
#		time_getYear        - get year from time-stamp
#		time_normalise      - clean up an array of time to represent a valid date
#		time_now            - returns the array of time of the current time in UTC
#		time_parse          - parse a time string into an array of time
#		time_pduCycle       - convert time into PDU cycle
#		time_printf         - formatted output of time
#		time_serialise      - for internal calculations, serialised time
#		time_setDate        - reset the year, month, and day of the given date
#		time_setYear        - reset the year   of the given date
#		time_setMonth       - reset the month  of the given date
#		time_setDay         - reset the day    of the given date
#		time_setTime        - reset the hour, minute, and second of the given date
#		time_setHour        - reset the hour   of the given date
#		time_setMinute      - reset the minute of the given date
#		time_setSecond      - reset the second of the given date
#		time_spanAdd        - add two time spans
#		time_spanMultiply   - multiply time span with scalar
#		time_spanNegate     - negate every element of the time array
#		time_spanSerialise  - for internal calculations, serialised time span
#		time_spanSubtract   - subtract two time spans
#		time_spanUnserialise- for internal calculations, serialised time
#		time_subtract	    - subtract a time span  from a given date
#		time_subYears       - subtract some years   from a given date
#		time_subMonths      - subtract some months  from a given date
#		time_subDays        - subtract some days    from a given date
#		time_subHours       - subtract some hours   from a given date
#		time_subMinutes     - subtract some minutes from a given date
#		time_subSeconds     - subtract some seconds from a given date
#		time_today          - array of time of the current day 0:00:00 in UTC
#		time_tomorrow       - array of time of tomorrow 0:00:00 in UTC
#		time_unserialise    - for internal calculations, serialised time
#		time_yesterday      - array of time of yesterday 0:00:00 in UTC
#
#	There are two types of "times" representing:
#		1. A valid absolute moment in the time, TIME
#		2. A difference between two moments in the time, TIMESPAN
#
#	The internal representation of TIMEs and TIMESPANs is an eight dimensional
#	ordered array like
#		( year month day hours minutes seconds milliseconds microseconds )
#
#	All time calculations are expected to be done in the same time zone. For
#	conversion between dates, all dates are expected to be Gregorian dates and
#	times are in UTC (Universal Coordinated Time).
#
#	The following arithmetic operations are permitted (all others are not):
#		Addition:
#			TIME     + TIMESPAN = TIME      (time_add)
#			TIMESPAN + TIMESPAN = TIMESPAN  (time_spanAdd)
#		Subtraction:
#			TIME     - TIME     = TIMESPAN  (time_diff)
#			TIME     - TIMESPAN = TIME      (time_subtract)
#			TIMESPAN - TIMESPAN = TIMESPAN  (time_spansubtract)
#		Multiplication:
#			TIMESPAN * number   = TIMESPAN  (time_spanMultiply)
#		Unitary minus:
#			-TIMESPAN           = TIMESPAN  (time_spanNegate)
#
#	Be careful when adding months or years because months have 28 to 31 days,
#	years have 365 or 366 days. The result therefore is normalised after
#	calculation. Example: adding 1 month to the 31. March would result in the
#	31. April, which does not exist. The result of that calculation will be the
#	1. May.
#
#	When the time span uses mixed positive and negative numbers, the result is
#	depended on the order of calculation. Imagine, we add 1 month to and
#	subtract 1 day from the date 1. Mar. 2001:
#		a) 1.Mar.2001 + 1 month =  1.Apr.2001 ... - 1 day   = 31.Mar.2001
#		b) 1.Mar.2001 - 1 day   = 28.Feb.2001 ... + 1 month = 28.Mar.2001
#	The functions in this library use scenario a, e.g. add years and months
#	first and then days, hours, etc.
#
# SEE ALSO
#
#	lib_calendar.bash
#
# AUTHOR
#
#	@author     Andreas Tusche (bash-libraries@andreas-tusche.de)
#	@copyright  (c) 2008, Andreas Tusche, <http://www.andreas-tusche.de/>
#	@package    bash_libraries
#	@version    $Revision: 0.0 $
#	@(#) $Id: . Exp $
#
# 2008-03-20 AnTu initial release

(( ${time_lib_loaded:-0} )) && return 0 # load me only once

###############################################################################
# config
###############################################################################

# format for input and output time strings
time_FORMAT="YYYY-MM-DD hh:mm:ss" # default input format for time_parse
#unset time_OFORMAT               # must be unset here , but may be set by user

#------------------------------------------------------------------------------
# --- nothing beyond this line should need configuration ! ---

# general global variables
time_DEBUG=${DEBUG:-0}                 # no debugging by default
time_VERBOSE=${VERBOSE:-0}             # verbose defaults to FALSE

# general global constants
readonly time_MY_VERSION='$Revision: 1.0 $' # version of this library
readonly time_UNKNOWN=-1               # for variables with unknown value (use with care)

###############################################################################
# all arguments are handled by the calling script, but in case help is needed
###############################################################################

if [[ "${0##*/}" == "lib_time.bash" && "$1" == "--help" ]] ; then
	awk '/^# NAME/,/^#===|^####/ {print l;sub(/^# ?/,"",$0);l=$0}' "${0%/*}/${0##*/}"
	exit
fi

###############################################################################
# Libraries
###############################################################################

(( $calendar_lib_loaded )) || source "${facility_lib%/}/lib_calendar.bash" || exit $ERR_LIB_NOT_FOUND

###############################################################################
# Functions
###############################################################################

#==============================================================================
# time_add - add a time span to a given date
#
# SYNOPSIS
#	time_add TIME TIMESPAN
#
# DESCRIPTION
#	This function takes two arrays of time and adds them.
#
#	The first array TIME has to be a valid date. The second array TIMESPAN
#	holds the numbers of years, months, days, etc. to add to the first one, it
#	does not need to represent a valid date but it must have all 8 values.
#
# OPTIONS
#	TIME TIMESPAN
#		Arrays of time, first a valid date, second a time span
#
# DIAGNOSTICS
#	This function returns an array of time representing a valid date.
#
# EXAMPLES
#	t1=( 1967 3 20 6 50 0 0 0 )
#	t2=(   42 0  0 0  0 0 0 0 )
#	time_add ${t1[@]} ${t2[@]}
#		This will add 42 years to the 20.March 1967 and results in the array of
#		time ( 2009 3 20 6 50 0 0 0 )
#
#	t1=( 2000 2 28  0 0 0 0 0 )
#	t2=(    8 0  1 36 0 0 0 0 )
#	time_add ${t1[@]} ${t2[@]}
#		This will add 8 years, one day and 36 hours to the 28.Feb 2000 and
#		results in the array of time ( 2008 3 1 12 0 0 0 0 ). This is because
#		2008 was a leap year and there were 29 days in February.
#
# GLOBAL VARIABLES SET
#	return                             # array holding the result
#
# SEE ALSO
#	time_spanAdd()   - add two time-spans
#	time_subtract()  - subtract time span from a given date
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.131018===

function time_add { # TIME TIMESPAN
	local s Y M D
	local -a t1 t2

	Y=$(( ${1:-0} + ${9:-0} ))                        # add years
	M=$(( ${2:-0} + ${10} ))                          # add months
	D=$(( ${3:-0} - 1 + ${11} ))                      # add days
	(( Y = Y + M / 12 , M = M % 12 ))                 # normalise years, months

	if (( $M < 1 )) ; then
		(( Y = Y - 1 , M = M + 12 ))                  # normalise if negative
	fi

	# The time in t1 already has added years and months. Now adding the rest.
	t1=$( time_serialise $Y $M 1 ${@:4:5} )           # in seconds
	t2=( $( time_spanSerialise  0  0 $D ${@:12:5} ) ) # in ( seconds months )
	s=$( echo $t1 " + " ${t2[0]} | bc )               # add seconds
	return=( $( time_unserialise $s ) )
	echo "${return[@]}"
}


#==============================================================================
# time_addYears   - add some years   to the given date keeping it normalised
# time_addMonths  - add some months  to the given date keeping it normalised
# time_addDays    - add some days    to the given date keeping it normalised
# time_addHours   - add some hours   to the given date keeping it normalised
# time_addMinutes - add some minutes to the given date keeping it normalised
# time_addSeconds - add some seconds to the given date keeping it normalised
#
# SYNOPSIS
#	time_addYears   TIME YEARS
#	time_addMonths  TIME MONTHS
#	time_addDays    TIME DAYS
#	time_addHours   TIME HOURS
#	time_addMinutes TIME MINUTES
#	time_addSeconds TIME SECONDS
#
# DESCRIPTION
#	These functions are simple wrapper functions to time_add
#
# OPTIONS
#	TIME
#		A valid array of time.
#
#	YEARS, MONTHS, etc.
#		An integer positive or negative number of years, months, etc.
#
# DIAGNOSTICS
#	These functions return a valid (normalised) array of time
#	to stdout and set the $return variable.
#
# EXAMPLE
#	t=( 1967 3 20 6 50 0 0 0 )
#	time_addMonths ${t[@]} 42
#
# GLOBAL VARIABLES SET
#	return                             # array holding the result
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.131018===

function time_addYears { # ( TIME YEARS )
	time_add ${@:1:8} ${9:-0} 0 0 0 0 0 0 0
}

function time_addMonths { # ( TIME MONTHS )
	time_add ${@:1:8} 0 ${9:-0} 0 0 0 0 0 0
}

function time_addDays { # ( TIME DAYS )
	time_add ${@:1:8} 0 0 ${9:-0} 0 0 0 0 0
}

function time_addHours { # ( TIME HOURS )
	time_add ${@:1:8} 0 0 0 ${9:-0} 0 0 0 0
}

function time_addMinutes { # ( TIME MINUTES )
	time_add ${@:1:8} 0 0 0 0 ${9:-0} 0 0 0
}

function time_addSeconds { # ( TIME SECONDS )
	time_add ${@:1:8} 0 0 0 0 0 ${9:-0} 0 0
}


#==============================================================================
# time_compare - compares two arrays of time
#
# SYNOPSIS
#	time_compare TIME1 TIME2
#
# DESCRIPTION
#	This function compares two array of time. Each array of time must have the
#	common layout:
#		( year month day hours minutes seconds milliseconds microseconds )
#	They both have to be valid dates.
#
#	If TIME1 is in the past of TIME2 the result will be -1.
#	If TIME1 is in the future of TIME2 the result will be 1.
#	If the TIME1 and TIME2 are the same, the result will be 0.
#
# OPTIONS
#	TIME1 TIME2
#		Arrays of valid dates (no time-spans)
#
# DIAGNOSTICS
#	This function returns an integer value.
#
# EXAMPLES
#	t1=( 1967 3 20 6 50 0 0 0 )
#	t2=( 2009 3 20 6 50 0 0 0 )
#	time_compare ${t1[@]} ${t2[@]}
#		This will return -1 because 1967 was earlier than 2009.
#
# GLOBAL VARIABLES SET
#	return                             # integer holding the result
#
# BUGS
#	No checking for valid dates is done
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.081013===

function time_compare { # TIME1 TIME2
	local t1 t2

	t1=$( time_serialise ${@:1:8} )
	t2=$( time_serialise ${@:9:8} )

	if [[ $t1 < $t2 ]] ; then
		return=-1
	elif [[ $t1 > $t2 ]] ; then
		return=1
	else
		return=0
	fi

	echo "${return}"
}


#==============================================================================
# time_convert - convert a timestamp from one format to another
#
# SYNOPSIS
#	time_convert TIMESTRING [[FORMAT1] FORMAT2]
#
# DESCRIPTION
#	This function converts a timestring from FORMAT1 to FORMAT2. If the formats
#	are omitted, their values will be taken from $time_FORMAT and $time_OFORMAT.
#
# OPTIONS
#	TIMESTRING 	A string representing a valid date (no time-spans)
#	FORMAT1     The input time format, see time_parse()
#	FORMAT2     The output time format, see time_printf()
#
# DIAGNOSTICS
#	This function returns the new timestring
#
# EXAMPLES
#	time_convert 24550:0024600000:00000 j2000 Ascii
#		This will return 20-MAR-2067 06:50:00.000000
#
# GLOBAL VARIABLES SET
#	return                             # string holding the result
#
# BUGS
#	No checking for valid dates is done
#
# SEE ALSO
#	time_parse()
#	time_printf()
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.081204===

function time_convert { # TIME [FORMAT1] FORMAT2
	# parameter(s) to function
	local t="${1:-0}"

	if (( $# == 2 )) ; then
		local format2="${2}"
	else
		local format1="${2:-$time_FORMAT}"
		local format2="${3:-$time_OFORMAT}"
	fi

	time_printf "$format2" $( time_parse "$t" "$format1" )
}


#==============================================================================
# time_diff - difference between two dates
#
# SYNOPSIS
#	time_diff TIME1 TIME2
#
# DESCRIPTION
#	This function calculates the difference between two arrays of time. Each
#	array of time must have the common layout:
#		( year month day hours minutes seconds milliseconds microseconds )
#	They both have to be valid dates.
#
#	The result is returned as an array of time but the years and the months are
#	always returned as 0, because of the different length of months (28 to 31
#	days) and years (365 to 366 days). The time difference is given in
#	days, hours, minutes, seconds, milliseconds and microseconds only.
#
# OPTIONS
#	TIME1 TIME2
#		Arrays of valid dates
#
# DIAGNOSTICS
#	This function returns an array of time.
#
# EXAMPLES
#	t1=( 1967 3 20 6 50 0 0 0 )
#	t2=( 2009 3 20 6 50 0 0 0 )
#	time_diff ${t1[@]} ${t2[@]}
#		This will calculate the difference between the 20.March 1967 and the
#		20.March 2009. The result is 15341 days, or written as  array of
#		time: ( 0 0 15341 0  0 0 0 0 )
#
#	t1=( 2000 2 28  0 0 0 0 0 )
#	t2=( 2008 3  1 12 0 0 0 0 )
#	time_diff ${t1[@]} ${t2[@]}
#		This will calculate the difference between the 28.February 2000 and the
#		1.March 2008 12:00. The result is 2924 days and 12 hours, or
#		written as array of time: ( 0 0 2924 12 0 0 0 0 )
#
# GLOBAL VARIABLES SET
#	return                             # array holding the result
#
# BUGS
#	No checking for valid dates is done
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.080702===

function time_diff { # TIME1 TIME2
	local s t1 t2
	local f="%.4d%.2d%.2d%.2d%.2d%.2d%.3d%.3d"

	t1=$( time_serialise ${@:1:8} )
	t2=$( time_serialise ${@:9:8} )

	if [[ $( printf $f ${@:1:8} ) < $( printf $f ${@:9:8} ) ]] ; then
		s=$( echo $t2 " - " $t1 | bc )
	else
		s=$( echo $t1 " - " $t2 | bc )
	fi

	return=( $( time_spanUnserialise $s 0 ) )
	echo "${return[@]}"
}


#==============================================================================
# time_getMonth - get month of year from a month's name or from a timestamp
#
# SYNOPSIS
#	time_getMonth [ TIME | MONTH ]
#
# DESCRIPTION
#	This function converts the English names of the Gregorian calendar months
#	in the number of the month (moy=month of year). It may also be used to
#	extract the month from an array of time.
#	If no option was given, it returns the current month.
#
# OPTIONS
#	TIME   An array of time
#	MONTH  At least three letters representing the name of a month
#
# DIAGNOSTICS
#	This function returns a number between 1 and 12 to stdout.
#	A return value of 0 (zero) indicates an error in the input.
#
# EXAMPLE
#	time_getMonth Mar
#		will return 3
#
#	time_getMonth 1967 3 20 6 50 0 8 15
#		will return 3
#
# GLOBAL VARIABLES SET
#	return                             # integer, holding the result
#
# SEE ALSO
#	time_getMonthName() - get month name
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.081112===

function time_getMonth { # [ TIME | NAME_OF_MONTH ]
	case ${#@} in
		0)
			return=$( date -u +"%m" ) ;;
		1)
			case $1 in
				Jan*|JAN*) return=1 ;;
				Feb*|FEB*) return=2 ;;
				Mar*|MAR*) return=3 ;;
				Apr*|APR*) return=4 ;;
				May|MAY)   return=5 ;;
				Jun*|JUN*) return=6 ;;
				Jul*|JUL*) return=7 ;;
				Aug*|AUG*) return=8 ;;
				Sep*|SEP*) return=9 ;;
				Oct*|OCT*) return=10 ;;
				Nov*|NOV*) return=11 ;;
				Dec*|DEC*) return=12 ;;
				*)         return=0 ;;
			esac
			;;
		*)
			return=$(( ($2 - 1 ) % 12 + 1 )) ;;
	esac

	echo $return
}


#==============================================================================
# time_getMonthName - get the month's name from a month of year
#
# SYNOPSIS
#	time_getMonthName MOY [FORMAT]
#
# DESCRIPTION
#	This function returns the English names of the Gregorian calendar months
#	from the number of the month (moy=month of year).
#
# OPTIONS
#	MOY
#		A number between 1 and 12 inclusive, giving the month of the year
#
#	FORMAT
#		A simple format string allowing for the first letter of the month name
#		to be capitalised or all letters, and to decide if you prefer full
#		length names or the short versions (3 chars). Valid values for FORMAT
#		are "MONTH", "Month", "MON", or "Mon". The default is "MON".
#
# DIAGNOSTICS
#	This function returns a string to  stdout.
#
# EXAMPLE
#	time_getMonthName 3 Month
#		will return "March"
#
# GLOBAL VARIABLES SET
#	return                             # string, holding the result
#
# SEE ALSO
#	time_getMonth()                                - get month of year
#	lib_calendar::calendar_gregorianMonthName      - as it says
#	lib_calendar::calendar_gregorianMonthNameShort - as it says
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.080702===

function time_getMonthName { # MONTH_OF_YEAR [FORMAT]
	case $2 in
		Month) return=${calendar_gregorianMonthName[$1]} ;;
		Mon)   return=${calendar_gregorianMonthNameShort[$1]} ;;
		MONTH) return=${calendar_gregorianMONTHName[$1]} ;;
		*)     return=${calendar_gregorianMONTHNameShort[$1]} ;;
	esac

	echo "$return"
}


#==============================================================================
# time_getYear - get year from timestamp
#
# SYNOPSIS
#	time_getYear [ TIME ]
#
# DESCRIPTION
#	This function extracts the year from an array of time
#	If no option was given, it returns the current year.
#
# OPTIONS
#	TIME   An array of time
#
# DIAGNOSTICS
#	This function returns an integer number.
#
# EXAMPLE
#	time_getYear 1967 3 20 6 50 0 8 15
#		will return 1967
#
# GLOBAL VARIABLES SET
#	return                             # integer, holding the result
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.081112===

function time_getYear { # [ TIME ]
	return=${1:-$( date -u +"%Y" )}
	echo $return
}


#==============================================================================
# time_normalise - clean up an array of time to represent a valid date
#
# SYNOPSIS
#	time_normalise TIME
#
# DESCRIPTION
#	This function cleans up an array of time to represent a valid date.
#
# OPTIONS
#	TIME  A (not necessarily well-formed) array of time.
#
# DIAGNOSTICS
#	This function returns an array of time to stdout.
#
# EXAMPLE
#	time_normalise 2008 2 31 0 0 0 0 0
#		The "31. February 2008" actually was the 2. March 2008. The
#		result will be: ( 2008 3 2 0 0 0 0 0 )
#
# GLOBAL VARIABLES SET
#	return                             # array, holding the result
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.131018===

function time_normalise { # ( TIME )
	return=( $( time_add ${1:-1} 1 1 0 0 0 0 0 0 $(( ${2:-0} - 1 )) $(( ${3:-0} - 1 )) ${4:-0} ${5:-0} ${6:-0} ${7:-0} ${8:-0} ) )
	echo "${return[@]}"
}

function time_normalize { time_normalise $@ ; } # alias


#==============================================================================
# time_now - returns the array of time of the current time in UTC
#
# SYNOPSIS
#	time_now
#
# DESCRIPTION
#	This function returns the array of time of the current time in UTC.
#
# DIAGNOSTICS
#	This function returns the array of time
#
# GLOBAL VARIABLES SET
#	return                             # array, holding the result
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.080630===

function time_now {
	time_parse "$( date -u +"%Y-%m-%d %T" )" "YYYY-MM-DD hh:mm:ss"
}


#==============================================================================
# time_parse - parse a time string into an array of time
#
# SYNOPSIS
#	time_parse TIMESTRING [FORMAT]
#
# DESCRIPTION
#	This function parses a string containing a date and time. It outputs an
#	array of time; like ( year month day hours minutes seconds millisecond
#	microseconds ).
#
# OPTIONS
#	TIME
#		A string giving the (Gregorian) date and time, in any format that is
#		supported by the FORMAT argument. Please keep in mind that any string
#		containing white-space must be quoted.
#
#	FORMAT
#		A format string describing the date format. All numbers are extracted
#		by their position within the string. The delimiters can be any of
#		"-", "_", ".", ":", ",", ";", " ", "/" and are interchangeable. The
#		milliseconds and microseconds are both optional. Please keep in mind
#		that any string containing white-space must be quoted.
#		Following formats and variations of them are supported:
#			"DD.MM.YYYY hh:mm:ss"      "DD.MM.YYYY hh:mm:ss.sssuuu"
#			"DD.MMM.YYYY hh:mm:ss"     "DD.MMM.YYYY hh:mm:ss.sssuuu"
#			"DD.MONTH.YYYY hh:mm:ss"   "DD.MONTH.YYYY hh:mm:ss.sssuuu"
#			"hh:mm:ss"                 "hh:mm:ss.sssuuu"
#			"MM/DD/YYYY hh:mm:ss"      "MM/DD/YYYY hh:mm:ss.sssuuu"
#			"YYYY DOY sss"
#			"YYYY-DOY-hh:mm:ss"        "YYYY-DOY-hh:mm:ss.sssuuu"
#			"YYYYDOY_hhmmss"           "YYYYDOY_hhmmss.sssuuu"
#			"YYYYDOYhhmmss"            "YYYYDOYhhmmss.sssuuu"
#			"YYYY-MM-DD hh:mm:ss"      "YYYY-MM-DD hh:mm:ss.sssuuu"
#			"YYYYMMDD hhmmss"          "YYYYMMDD hhmmss.sssuuu"
#			"YYYYMMDDhhmmss"           "YYYYMMDDhhmmss.sssuuu"
#
#		The FORMAT allows some special cases as well:
#			"Ascii" - same as "DD.MONTH.YYYY hh:mm:ss.sssuuu"
#			"rsat"  - same as "YYYY-DOY-hh:mm:ss.sss"
#			"j2000" - days since 1 Jan 2000 : milliseconds : microseconds
#			"msec"  - milliseconds since midnight of "today"
#			"UNIX"  - input is the Unix time in seconds since 1. Jan. 1970
#			"xml"   - date and time are separated by the letter "T" like in
#			          YYYY-MM-DDThh:mm:ss.sssuuu
#
#		If the FORMAT string is omitted, the default from $time_FORMAT is used.
#
# DIAGNOSTICS
#	This function returns the array of time.
#
# EXAMPLE
#	time_parse "19670320 065000" "YYYYMMDD hhmmss"
#		This results in ( 1967 3 20 6 50 0 0 0 )
#
#	time_parse "20.3.1967 6:50" "DD.MM.YYYY hh:mm:ss"
#		This is a special case. Whenever all elements of the time string are
#		separated by delimiters, the leading zero may be omitted. But anyhow
#		the format string has to reflect the fully qualified format.
#		This results in ( 1967 3 20 6 50 0 0 0 ) as well.
#
# GLOBAL VARIABLES USED
#	time_FORMAT                        # the default format
#
# GLOBAL VARIABLES SET
#	return                             # array holding the result
#
# BUGS
#	No checking for valid dates is done
#
# SEE ALSO
#	lib_tstamp::tstamp_parse() - a special case with different output array
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.090728===
# --!-- TODO: add formats: mjd2000, utc, jd1950

function time_parse { # TIMESTRING FORMAT
	# parameter(s) to function
	local t="${1:-0}"
	local format="${2:-$time_FORMAT}"

	# variables local
	local oldIFS="${IFS}"
	local -a a ymd
	local year month day h m s ms us tmp
	local doy=$time_UNKNOWN
	local x="[-_.:,\;\ /T]" # possible delimiters

	return=$time_UNKNOWN

	case "$format" in
		YYYY${x}MM${x}DD${x}hh${x}mm${x}ss*|[xX][mM][lL])
			IFS="[-_.:,;\ /]" a=( $t )   # split up the time into an array
			year=${a[0]}
			month=${a[1]}
			day=${a[2]}
			h=${a[3]}
			m=${a[4]}
			s=${a[5]}
			tmp="${a[6]}000000"
			ms=${tmp:0:3}
			us=${tmp:3:3}
			;;
		YYYY${x}M[MOmo][MNmn]*${x}DD${x}hh${x}mm${x}ss*)
			IFS="[-_.:,;\ /]" a=( $t )   # split up the time into an array
			year=${a[0]}
			month=$( time_getMonth ${a[1]} )
			day=${a[2]}
			h=${a[3]}
			m=${a[4]}
			s=${a[5]}
			tmp="${a[6]}000000"
			ms=${tmp:0:3}
			us=${tmp:3:3}
			;;
		YYYYMMDD${x}hhmmss*)
			year=${t:0:4}
			month=${t:4:2}
			day=${t:6:2}
			h=${t:9:2}
			m=${t:11:2}
			s=${t:13:2}
			ms=${t:16:3}
			us=${t:19:3}
			;;
		YYYYMMDDhhmmss*)
			year=${t:0:4}
			month=${t:4:2}
			day=${t:6:2}
			h=${t:8:2}
			m=${t:10:2}
			s=${t:12:2}
			ms=${t:15:3}
			us=${t:18:3}
			;;
		YYYYMMDD)
			year=${t:0:4}
			month=${t:4:2}
			day=${t:6:2}
			h=0
			m=0
			s=0
			ms=0
			us=0
			;;
		YYYY${x}DOY${x}hh${x}mm${x}ss*|[]rR[sS][aA][tT])
			IFS="[-_.:,;\ /]" a=( $t )   # split up the time into an array
			year=${a[0]:-0}
			doy=${a[1]:-0}
			h=${a[2]}
			m=${a[3]}
			s=${a[4]}
			tmp="${a[5]}000000"
			ms=${tmp:0:3}
			us=${tmp:3:3}
			;;
		YYYYDOY${x}hhmmss*)
			year=${t:0:4}
			doy=${t:4:3}
			h=${t:8:2}
			m=${t:10:2}
			s=${t:12:2}
			ms=${t:15:3}
			us=${t:18:3}
			;;
		YYYYDOYhhmmss*)
			year=${t:0:4}
			doy=${t:4:3}
			h=${t:7:2}
			m=${t:9:2}
			s=${t:11:2}
			ms=${t:14:3}
			us=${t:17:3}
			;;
		YYYY${x}DOY${x}sss|YYYY${x}DOY${x}ms)
			IFS="[-_.:,;\ /]" a=( $t )   # split up the time into an array
			year=${a[0]}
			doy=${a[1]}
			ms=${a[2]}
			((
				h = ms / 3600000 , ms = ms % 3600000 ,
				m = ms /   60000 , ms = ms %   60000 ,
				s = ms /    1000 , ms = ms %    1000
			))
			us=0
			;;
		DD${x}M[MOmo][MNmn]*${x}YYYY${x}hh${x}mm${x}ss*|[aA][sS][cC][iI][iI])
			IFS="[-_.:,;\ /]" a=( $t )   # split up the time into an array
			year=${a[2]}
			month=$( time_getMonth ${a[1]} )
			day=${a[0]}
			h=${a[3]}
			m=${a[4]}
			s=${a[5]}
			tmp="${a[6]}000000"
			ms=${tmp:0:3}
			us=${tmp:3:3}
			;;
		DD${x}MM${x}YYYY${x}hh${x}mm${x}ss*)
			IFS="[-_.:,;\ /]" a=( $t )   # split up the time into an array
			year=${a[2]}
			month=${a[1]}
			day=${a[0]}
			h=${a[3]}
			m=${a[4]}
			s=${a[5]}
			tmp="${a[6]}000000"
			ms=${tmp:0:3}
			us=${tmp:3:3}
			;;
		MM${x}DD${x}YYYY${x}hh${x}mm${x}ss*)
			IFS="[-_.:,;\ /]" a=( $t )   # split up the time into an array
			year=${a[2]}
			month=${a[0]}
			day=${a[1]}
			h=${a[3]}
			m=${a[4]}
			s=${a[5]}
			tmp="${a[6]}000000"
			ms=${tmp:0:3}
			us=${tmp:3:3}
			;;
		hh${x}mm${x}ss*)
			IFS="[-_.:,;\ /]" a=( $t )   # split up the time into an array
			year=0
			month=0
			day=0
			h=${a[0]}
			m=${a[1]}
			s=${a[2]}
			tmp="${a[3]}000000"
			ms=${tmp:0:3}
			us=${tmp:3:3}
			;;
		[jJ]2000*)
			IFS=":" a=( $t )   # split up the time into an array
			shopt -s extglob
			d2=${a[0]} ; d2=$(( ${d2##+(0)} + 1 )) # !
			ms=${a[1]} ; ms=$(( ${ms##+(0)} + 0 ))
			us=${a[2]} ; us=$(( ${us##+(0)} + 0 ))
			shopt -u extglob
			return=( 2000 1 $d2 0 0 0 $ms $us ) # normalising will be done later
			;;
		msec)
			return=( $( date -u +"%Y %m %d" ) 0 0 0 $t 0 ) # normalising will be done later
			;;
		[uU][nN][iI][xX])
			return=( $( time_addSeconds 1970 1 1 0 0 0 0 0  $t ) )
			;;
		*)
			# --!-- Try to find out the format from the timestamp itself
			echo "ERROR: time format $format not (yet) implemented." >&2
			return $ERR_NOT_IMPLEMENTED
			;;
	esac

	IFS="${oldIFS}"

	if [[ "$return" == "$time_UNKNOWN" ]] ; then
		# get rid of leading zeros
		shopt -s extglob
		year=$(( ${year##+(0)} + 0 ))

		if [[ "$doy" != "$time_UNKNOWN" ]] ; then
			doy=$(( ${doy##+(0)} + 0 ))
			ymd=( $( calendar_doyToGregorian $year $doy ) )
			month=${ymd[1]}
			day=${ymd[2]}
		fi

		month=$(( ${month##+(0)} + 0 ))
		day=$(( ${day##+(0)} + 0 ))
		h=$(( ${h##+(0)} + 0 ))
		m=$(( ${m##+(0)} + 0 ))
		s=$(( ${s##+(0)} + 0 ))
		ms=$(( ${ms##+(0)} + 0 ))
		us=$(( ${us##+(0)} + 0 ))
		shopt -u extglob

		return=( $year $month $day $h $m $s $ms $us )
	fi

	if (( ${return[1]} != 0 && ${return[2]} != 0 )) ; then
		return=( $( time_normalise ${return[@]} ) )
 	fi

	echo "${return[@]}"
}

#==============================================================================
# time_pduCycle - convert time into PDU cycle
#
# SYNOPSIS
#	time_pduCycle [hh mm | TIME]
#
# DESCRIPTION
#	A PDU cycle is the number of a three minutes time span during a day.
#	The first PDU cycle starts at 0:00:00 and ends at 0:02:59 and has the
#	PDU cycle number 0 (zero), the next one starts at 0:03:00 and ends at
#	0:05:59 and has the cycle number 1, and so on. There are 480 PDU cycles
#	per day.
#
# OPTIONS
#	hh mm	Integer values of the hours and minutes.
#
#	TIME	An array of time. Only the hours and minutes are used
#
# EXAMPLE
#	time_pduCycle 6 50
#		This returns 136
#
#	time_pduCycle 1967 3 20 6 50 0 0 0
#		This returns 136
#
# GLOBAL VARIABLES SET
#	return                             # integer holding the result
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.080915===

function time_pduCycle { # TIME
	local h m
	if (( $# == 2 )) ; then
		h=$1
		m=$2
	else
		h=$4
		m=$5
	fi
	
	return=$( echo $h $m | awk '{ print int ( $1 * 20 + $2 / 3 + 0.3 )}' )

	echo $return
}

#==============================================================================
# time_printf - print formatted time
#
# SYNOPSIS
#	time_printf [FORMAT] TIME
#
# DESCRIPTION
#	The given array of time is formatted and printed. the format may be given as
#	the first argument. If it is omitted, then the default value from the
#	global variable time_OFORMAT or time_FORMAT is taken.
#
#	Any combination of the following format strings are supported
#		MONTH, Month
#		MMMM, Mmmm, YYYY
#		DOY, MMM, Mmm, MON, Mon, sss, uuu
#		MM, DD, hh, mm, ss
#		%a, %A, %b, %B, %c, %C, %d, %D, %e, %h, %, %I, %j, %m, %M, %n,
#		%p, %r, %S, %t, %T, %u, %w, %y, %Y, %Z, %%
#
#	The FORMAT allows some special cases as well:
#		Ascii  - same as "DD-MMM-YYYY hh:mm:ss.sssuuu"
#		j2000  - days since 1 Jan 2000 : milliseconds : microseconds
#		jd2000 - days since 1 Jan 2000 . fraction of day as double
#		rsat   - same as "YYYY-DOY-hh:mm:ss.sss"
#		unix   - seconds since 1 Jan 1970 (without fractions)
#
#	And the formats from the 'printf' command are supported, but the
#	parameters are always in the order of the given array of time.
#
#	If the FORMAT string is omitted, the default from $time_OFORMAT is used.
#
# OPTIONS
#	FORMAT  A string describing the output.
#	TIME    An array of time representing a valid date
#
# DIAGNOSTICS
#	This function returns the formatted string to stdout.
#
# EXAMPLE
#	t=( 2001 2 3 4 5 6 700 800 )
#	time_printf "DD.MM.YYYY hh:mm:ss" ${t[@]}
#		This prints "03.02.2001 04:05:06"
#
#	time_printf "Ascii" ${t[@]}
#		This prints "03-FEB-2001 04:05:06.700800"
#
# GLOBAL VARIABLES SET
#	return                             # array holding the result
#
# SEE ALSO
#	The 'date' command
#
# BUGS
#	very likely
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.090722===

function time_printf { # [FORMAT] TIME
	local d2 doy format m ms

	case $1 in
		*[!0-9]*)    format="$1" ; shift ;;                     # at least one non-numerical character
		*[!a-zA-Z]*) format="${time_OFORMAT:-$time_FORMAT}" ;;  # without any letters
		*)
			echo "Unknown format '$1'." >&2
			exit $ERR_UNKNOWN_ARGUMENT
			;;
	esac

	case "$format" in
		[aA][sS][cC][iI][iI])
			m=$( time_getMonthName $2 "MON" )
			printf "%.2d-%s-%.4d %.2d:%.2d:%.2d.%.3d%.3d" $3 $m $1 $4 $5 $6 $7 $8
			;;
		[jJ]2000)
			d2=$(( $(calendar_gregorianToSdn $1 $2 $3) - $(calendar_gregorianToSdn 2000 1 1) ))
			ms=$(( $4 * 3600000 + $5 * 60000 + $6 * 1000 + $7 ))
			printf "%5.5d:%10.10d:%5.5d" $d2 $ms $8
			;;
		[jJ][dD]2000)
			d2=$(( $(calendar_gregorianToSdn $1 $2 $3) - $(calendar_gregorianToSdn 2000 1 1) ))
			frac=`echo "scale=16 ; ( $4 * 3600000000 + $5 * 60000000 + $6 * 1000000 + $7 * 1000 + $8 ) / 8640000000 + $d2" | bc`
			printf "%.12f" $frac
			;;
		[rR][sS][aA][tT])
			doy=$( calendar_gregorianToDoy $@ )
			printf "%.4d-%.3d-%.2d:%.2d:%.2d.%.3d" $1 $doy $4 $5 $6 $7
			;;
		[uU][nN][iI][xX])
			local dsec=210866803200 # =$( time_serialise 1970 1 1 0 0 0 0 0 )
			local sec=$( time_serialise $@ )
			printf "%.0f" $( echo "$sec - $dsec" | bc )
			;;
		*)
			local _w=$( calendar_dayOfWeek $( calendar_gregorianToDoy $@ ) )

			local _C=$( printf "%.2d" $(( $1 / 100 )) )
			local _I=$( printf "%.2d" $(( ($4 - 1) % 12 + 1 )) )
			local _p=$( if (( $4 > 11 )) ; then echo "PM" ; else echo "AM" ; fi )
			local _u=$(( $_w + 1 ))

			local _YYYY=$(  printf "%.4d" $1 )
			local _MM=$(    printf "%.2d" $2 )
			local _DD=$(    printf "%.2d" $3 )
			local _hh=$(    printf "%.2d" $4 )
			local _mm=$(    printf "%.2d" $5 )
			local _ss=$(    printf "%.2d" $6 )
			local _sss=$(   printf "%.3d" $7 )
			local _uuu=$(   printf "%.3d" $8 )

			local _YY=$(    printf "%.2d" $(( $1 % 100 )) )

			local _DDD=${calendar_dayNameShort[$_w]}
			local _DOY=$(   printf "%.3d" $( calendar_gregorianToDoy $@ ) )
			local _MMM=${calendar_gregorianMONTHNameShort[$2]}
			local _Mmm=${calendar_gregorianMonthNameShort[$2]}

			local _DDDD=${calendar_dayName[$_w]}
			local _MMMM=${calendar_gregorianMONTHName[$2]}
			local _Mmmm=${calendar_gregorianMonthName[$2]}

			format="${format//MONTH/$_MMMM}"
			format="${format//Month/$_Mmmm}"

			format="${format//MMMM/$_MMMM}"
			format="${format//Mmmm/$_Mmmm}"
			format="${format//YYYY/$_YYYY}"

			format="${format//DOY/$_DOY}"
			format="${format//MMM/$_MMM}"
			format="${format//Mmm/$_Mmm}"
			format="${format//MON/$_MMM}"
			format="${format//Mon/$_Mmm}"
			format="${format//sss/$_sss}"
			format="${format//uuu/$_uuu}"

			format="${format//MM/$_MM}"
			format="${format//DD/$_DD}"
			format="${format//hh/$_hh}"
			format="${format//mm/$_mm}"
			format="${format//ss/$_ss}"

			format="${format//\\%a/$_DDD}"        # abbreviated weekday name.
			format="${format//\\%A/$_DDDD}"       # full weekday name.
			format="${format//\\%b/$_MMM}"        # abbreviated month name.
			format="${format//\\%B/$_MMMM}"       # full month name.
			format="${format//\\%c/${_YYYY}-${_MM}-${_DD}-${_hh}:${_mm}:${_ss}.${_sss}${_uuu}}" # appropriate date and time representation
			format="${format//\\%C/$_C}"          # century as a decimal number (00-99)
			format="${format//\\%d/$_DD}"         # day of the month as a decimal number (01-31)
			format="${format//\\%D/${_MM}/${_DD}/${_YY}}" # date in the format equivalent to %m/%d/%y.
			format="${format//\\%e/$3}"           # day of the month as a decimal number (1-31)
			format="${format//\\%h/$_MMM}"        # abbreviated month name (a synonym for %b).
			format="${format//\\%H/$$_hh}"        # hour (24-hour clock) as a decimal number (00-23)
			format="${format//\\%I/$_I}"          # hour (12-hour clock) as a decimal number (01-12)
			format="${format//\\%j/$_DOY}"        # day of year as a decimal number (001-366)
			format="${format//\\%m/$_MM}"         # month of year as a decimal number (01-12)
			format="${format//\\%M/$_mm}"         # minutes as a decimal number (00-59)
			format="${format//\\%n/\\n}"          # Inserts a <new-line> character.
			format="${format//\\%p/$_p}"          # equivalent of either AM or PM.
			format="${format//\\%r/${_I}:${_mm}:${_ss} ${_p}}" # 12-hour clock time (01-12) using the AM-PM notation;  this is equivalent to %I:%M:%S %p
			format="${format//\\%S/${_ss}}"       # seconds as a decimal number (00-59)
			format="${format//\\%t/\\t}"          # Inserts a <tab> character.
			format="${format//\\%T/${_hh}:${_mm}:${_ss}}" # 24-hour clock (00-23) in the format equivalent to HH:MM:SS
			format="${format//\\%u/$_u}"          # weekday as a decimal number from 1-7 (Sunday = 7). Refer to the
#			format="${format//\\%U/}"             # -!- ToDo week of the year (Sunday as the first day of the week) as a decimal number[00 - 53] . All days in a new year preceding the first Sunday are considered to be in week 0.
#			format="${format//\\%V/}"             # -!- ToDo week of the year as a decimal number from 01-53 (Monday is used as the first day of the week). If the week containing January 1 has four or more days in the new year, then it is considered week 01; otherwise, it is week 53 of the previous year.
			format="${format//\\%w/$_w}"          # weekday as a decimal number from 0-6 (Sunday = 0)
#			format="${format//\\%W/}"             # -!- ToDo week number of the year as a decimal number (00-53) counting Monday as the first day of the week.
#			format="${format//\\%x/}"             # -!- ToDo locale's appropriate date representation.
#			format="${format//\\%X/}"             # -!- ToDo locale's appropriate time representation.
			format="${format//\\%y/$_YY}"         # last two numbers of the year (00-99)
			format="${format//\\%Y/$_YYYY}"       # year with century as a decimal number
#			format="${format//\\%Z/}"             # time-zone name, or no characters if no time zone is determinable.
			format="${format//\\%%/%}"            # a % (percent sign) character.
			format="${format//\\\\/}"             # remove backslashes

			printf "$format" $@
			;;
	esac

	printf "\n"
}


#==============================================================================
# time_serialise - creates a serialised version of date and time, internal use
#
# SYNOPSIS
#	time_serialise TIME
#
# DESCRIPTION
#	This function takes an array of time representing a valid date and converts
#	it into a serial number of seconds (with fractions).
#	This actually is the number of seconds since 12. November, 4714 BC
#
# OPTIONS
#	TIME  An array of time representing a valid date
#
# DIAGNOSTICS
#	This function returns an array of serialised time.
#
# EXAMPLE
#	time_serialise 2001 1 2 3 4 5 678 901
#		The input represents a valid date and the a serial seconds number can
#		be calculated. Is returns 211845207845.678901
#
# GLOBAL VARIABLES SET
#	return                             # array holding the result
#
# SEE ALSO
#	time_spanSerialise - same for time spans
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.080630===

function time_serialise { # TIME
	return=$( echo "scale=6; ( " $( calendar_gregorianToSdn ${@:1:3} ) " * 24 + " $4 " ) * 3600 + " $5 " * 60 + " $6 " + " $7 " / 1000 + " $8 " / 1000000 " | bc )
	echo $return
}

function time_serialize { time_serialise $@ ; }            # alias


#==============================================================================
# time_setDate    - reset the year, month, and day of the given date
# time_setYear    - reset the year   of the given date
# time_setMonths  - reset the month  of the given date
# time_setDays    - reset the day    of the given date
# time_setTime    - reset the hour, minute, and second of the given date
# time_setHours   - reset the hour   of the given date
# time_setMinutes - reset the minute of the given date
# time_setSeconds - reset the second of the given date
#
# SYNOPSIS
#	time_setDate   TIME YEAR MONTH DAY
#	time_setYear   TIME YEAR
#	time_setMonth  TIME MONTH
#	time_setDay    TIME DAY
#	time_setTime   TIME HOUR MINUTE SECOND
#	time_setHour   TIME HOUR
#	time_setMinute TIME MINUTE
#	time_setSecond TIME SECOND
#
# DESCRIPTION
#	These functions change only one value within the array of time but don't
#	change the values of the other fields, except for time_setTime() that sets
#	the milliseconds and microseconds to 0.
#
# OPTIONS
#	TIME
#		A valid array of time.
#
#	YEAR, MONTH, etc.
#		An integer positive or negative number of year, month, etc..
#
# DIAGNOSTICS
#	These functions return an array of time to stdout and set the $return
#	variable.
#
# EXAMPLE
#	t=( 1967 7 20 6 50 0 0 0 )
#	time_setMonth ${t[@]} 3
#
# GLOBAL VARIABLES SET
#	return                             # array holding the result
#
# BUGS
#	By applying an invalid number, the array of time may no longer represent
#	a valid date. e.g. setting the day to 31 for a February will be possible but
#	not valid.
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.080625===

function time_setDate { # ( TIME YEAR MONTH DAY )
	return=( ${9:-0} ${10:-1} ${11:-1} ${@:4:5} )
	echo "${return[@]}"
}

function time_setYear { # ( TIME YEAR )
	return=( ${9:-0} ${@:2:7} )
	echo "${return[@]}"
}

function time_setMonth { # ( TIME MONTH )
	return=( $1 ${9:-1} ${@:3:6} )
	echo "${return[@]}"
}

function time_setDay { # ( TIME DAY )
	return=( ${@:1:2} ${9:-1} ${@:4:5} )
	echo "${return[@]}"
}

function time_setTime { # ( TIME HOUR MINUTE SECOND )
	return=( ${@:1:3} ${@:9:3} 0 0 )
	echo "${return[@]}"
}

function time_setHour { # ( TIME HOUR )
	return=( ${@:1:3} ${9:-0} ${@:5:4} )
	echo "${return[@]}"
}

function time_setMinute { # ( TIME MINUTE )
	return=( ${@:1:4} ${9:-0} ${@:6:3} )
	echo "${return[@]}"
}

function time_setSecond { # ( TIME SECOND )
	return=( ${@:1:5} ${9:-0} ${@:7:2} )
	echo "${return[@]}"
}

#==============================================================================
# time_spanAdd - add two time spans
#
# SYNOPSIS
#	time_spanAdd TIMESPAN TIMESPAN
#
# DESCRIPTION
#	This function takes two arrays of time and adds them.
#
# OPTIONS
#	TIMESPAN TIMESPAN
#		Arrays of a time, both representing a time span
#
# DIAGNOSTICS
#	This function returns an array of time representing a time span.
#
# EXAMPLE
#	t1=( 2000 2 28  0 0 0 0 0 )
#	t2=(    8 0  1 36 0 0 0 0 )
#	time_add ${t1[@]} ${t2[@]}
#		The first array is not interpreted as a valid date. This results in the
#		array of time ( 2008 2 30 12 0 0 0 0 ), which is _not_ to interpreted
#		as a date like "30. Feb. 2008" but it represents a time span.
#
# GLOBAL VARIABLES SET
#	return                             # array holding the result
#
# SEE ALSO
#	time_add - add timespan to a given date
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.080701===

function time_spanAdd { # TIMESPAN TIMESPAN
	local -a s t1 t2
	t1=( $( time_spanSerialise ${@:1:8} ) )           # in ( seconds months )
	t2=( $( time_spanSerialise ${@:9:8} ) )           # in ( seconds months )
	s=$( echo ${t1[0]} " + " ${t2[0]} | bc )          # add seconds
	return=( $( time_spanUnserialise $s $(( ${t1[1]} + ${t2[1]} )) ) )
	echo "${return[@]}"
}


#==============================================================================
# time_spanMultiply - multiply a time span with a scalar
#
# SYNOPSIS
#	time_spanMultiply TIMESPAN NUMBER
#
# DESCRIPTION
#	This function multiplies a time span with a number
#
# OPTIONS
#	TIMESPAN
#		Arrays of time, representing a time span
#
#	NUMBER
#		Any number (defaults to 1)
#
# DIAGNOSTICS
#	This function returns an array of time representing a time span.
#
# EXAMPLE
#	t=( 0 6 0 12 0 0 0 0 )
#	time_spanMultiply ${t[@]} 2
#		Half a year and 12 hours multiplied by two results in a year and a day.
#		The result is ( 1 0 1 0 0 0 0 0 )
#
#	t=( 0 6 0 12 0 0 0 0 )
#	time_spanMultiply ${t[@]} 0.25
#		Be careful with multiplying fractions. The result is always rounded to
#		the next lower integer value, in this case affecting the count of
#		months. The result is ( 0 1 0 3 0 0 0 0 )
#
# GLOBAL VARIABLES SET
#	return                             # array holding the result
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.131018===

function time_spanMultiply { # TIMESPAN SCALAR
	local M s x=${9:-1}
	local -a t

	t=( $( time_spanSerialise ${@:1:8} ) )           # in ( seconds months )
	s=$( echo ${t[0]} " * " $x | bc )
	M=$( echo ${t[1]} " * " $x | bc )
	return=( $( time_spanUnserialise $s $M ) )
	echo "${return[@]}"
}


#==============================================================================
# time_spanNegate - negate every element of the time array
#
# SYNOPSIS
#	time_spanNegate TIME
#
# DESCRIPTION
#	This function negates every element of the array of time.
#
# OPTIONS
#	TIME
#		array of time
#
# DIAGNOSTICS
#	This function returns the resulting array of time to stdout.
#
# EXAMPLE
#	time_spanNegate 0 0 42 0 0 0 0 100
#		This returns ( 0 0 -42 0 0 0 0 -100 )
#
# GLOBAL VARIABLES SET
#	return                             # array holding the result
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.131018===

function time_spanNegate { # TIMESPAN
	return=( $(( 0 - ${1:-0} )) $(( 0 - ${2:-0} )) $(( 0 - ${3:-0} )) $(( 0 - ${4:-0} )) $(( 0 - ${5:-0} )) $(( 0 - ${6:-0} )) $(( 0 - ${7:-0} )) $(( 0 - ${8:-0} )) )
	echo "${return[@]}"
}

#==============================================================================
# time_spanSerialise - creates a serialised version of a time span
#
# SYNOPSIS
#	time_spanSerialise TIMESPAN
#
# DESCRIPTION
#	This function takes an array of time representing a time span and converts
#	it into a number of seconds (with fractions) and a number of months.
#
# OPTIONS
#	 TIMESPAN
#		An array of time representing a time span.
#
# DIAGNOSTICS
#	This function returns an array of serialised time.
#
# EXAMPLE
#	time_spanSerialise 2001 1 2 3 4 5 678 901
#		The input is not interpreted as a valid date but as a time span. The
#		number of seconds is calculated without taking months or years into
#		account. It returns (183845.678901 24013)
#
# GLOBAL VARIABLES SET
#	return                             # array holding the result
#
# SEE ALSO
#	time_serialse - creates a serialised version of a valid date
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.131018===

function time_spanSerialise { # TIMESPAN
	return=( $( echo "scale=6; ( " $3 " * 24 + " $4 " ) * 3600 + " $5 " * 60 + " $6 " + " $7 " / 1000 + " $8 " / 1000000 " | bc ) $(( ${1:-0} * 12 + ${2:-0} )) )
	echo "${return[@]}"
}                                                                             #"

function time_spanSerialize { time_spanSerialise $@ ; }    # alias


#==============================================================================
# time_spanSubtract - subtract two time spans
#
# SYNOPSIS
#	time_spanSubtract TIMESPAN TIMESPAN
#
# DESCRIPTION
#	This function takes two arrays of time and adds them.
#
# OPTIONS
#	TIMESPAN TIMESPAN
#		Arrays of a time, both representing a time span
#
# DIAGNOSTICS
#	This function returns an array of time representing a time span.
#
# EXAMPLES
#	t1=( 0 1 1 0 0 0 0 0 )
#	t2=( 0 2 2 0 0 0 0 0 )
#	time_spanSubtract ${t1[@]} ${t2[@]}
#		This will subtract 2 months and 2 days from a time span that was 1
#		month and 1 day. This should give a negative result. The result is
#		the time span ( 0 -1 -1 0 0 0 0 0 )
#
#	t1=( 1 1 1 0 0 0 0 0 )
#	t2=( 0 2 2 0 0 0 0 0 )
#	time_spanSubtract ${t1[@]} ${t2[@]}
#		This will subtract 2 months and 2 days from a time span that was 1
#		year, 1 month and 1 day. ThThe result now is the time span
#		( 0 11 -1 0 0 0 0 0 ). Note that we have a positive number of months
#		and a negative number of days.
#
# GLOBAL VARIABLES SET
#	return                             # array holding the result
#
# SEE ALSO
#	time_subtract
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.080701===

function time_spanSubtract { # TIMESPAN TIMESPAN
	time_spanAdd ${@:1:8} $( time_spanNegate ${@:9:8} )
}


#==============================================================================
# time_spanUnserialise - converts a serialised time span into an array of time
#
# SYNOPSIS
#	time_spanUnserialise SECONDS MONTHS
#
# DESCRIPTION
#	This function takes a serialised time span in SECONDS and MONTHS and
#	converts it in an array of TIME representing a time span.
#
# OPTIONS
#	SECONDS MONTHS
#		The serialised time span.
#
# DIAGNOSTICS
#	This function returns an array of time representing a time span to stdout.
#
# EXAMPLE
#	time_spanUnserialise 4711 42
#		This returns ( 3 6 0 1 18 31 0 0 )
#
# GLOBAL VARIABLES SET
#	return                             # array holding the result
#
# SEE ALSO
#	time_unserialise - converts a serialised time into an array of time
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.080630===

function time_spanUnserialise { # SERIALISED_TIMESPAN
	local -a tmp=( $( echo '
		t = '$1'
		u =   t % 0.001 * 1000000   ; t -= u / 1000000
		i = ( t % 1     ) * 1000    ; t -= i / 1000
		s = ( t % 60    )           ; t -= s
		m = ( t % 3600  )  / 60     ; t -= m * 60
		h = ( t % 86400 ) / 3600    ; t -= h * 3600
		d = t / 86400
		o = '${2:-0}'
		n = o % 12                  ; o -= n / 12
		y = o / 12
		y ; n ; d ; h ; m ; s ; i ; u' | bc ) )

	return=( ${tmp[0]%%.*} ${tmp[1]%%.*} ${tmp[2]%%.*} ${tmp[3]%%.*} ${tmp[4]%%.*} $(( ${tmp[5]%%.*} + 0 )) $(( ${tmp[6]%%.*} + 0 )) ${tmp[7]%%.*} )
	echo "${return[@]}"
}

function time_spanUnserialize { time_spanUnserialise $@ ; }     # alias


#==============================================================================
# time_subtract - subtract two arrays of time
#
# SYNOPSIS
#	time_subtract TIME TIMESPAN
#
# DESCRIPTION
#	This function takes two arrays of time and subtracts them.
#
#	The first array TIME has to be a valid date. The second array TIMESPAN
#	holds the numbers of years, months, days, etc. to subtract from the first
#	one, it does not need to represent a valid date but it must have all
#	8 values.
#
#	Be careful when subtracting months or years because months have 28 to 31
#	days, years have 365 or 366 days. The result therefore is normalised after
#	calculation. Example: subtracting 1 month from the 31. March would result
#	in the 31. February, which does not exist. The result of that calculation
#	will be the 2. or 3. March, depending on the year, if it was a leap year.
#
# OPTIONS
#	TIME
#		An array of a valid date
#
#	TIMESPAN
#		An array of years, months, days, etc. to be subtracted from the given
#		TIME
#
# DIAGNOSTICS
#	This function returns an array of time representing a valid date.
#
# EXAMPLES
#	t1=( 1967 3 20 6 50 0 0 0 )
#	t2=(   42 0  0 0  0 0 0 0 )
#	time_subtract ${t1[@]} ${t2[@]}
#		This will subtract 42 years from the 20.March 1967 and results in the
#		array of time ( 1925 3 20 6 50 0 0 0 )
#
#	t1=( 2000 3 1  0 0 0 0 0 )
#	t2=(    8 0 1 36 0 0 0 0 )
#	time_subtract ${t1[@]} ${t2[@]}
#		This will subtract 8 years, one day and 36 hours from the 1. Mar 2000
#		and results in the array of time ( 1992 2 27 12 0 0 0 0 ).
#
# GLOBAL VARIABLES SET
#	return                             # array holding the result
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.080701===

function time_subtract { # TIME TIMESPAN
	time_add ${@:1:8} $( time_spanNegate ${@:9:8} )
}


#==============================================================================
# time_subYears   - subtract years   from the given date keeping it normalised
# time_subMonths  - subtract months  from the given date keeping it normalised
# time_subDays    - subtract days    from the given date keeping it normalised
# time_subHours   - subtract hours   from the given date keeping it normalised
# time_subMinutes - subtract minutes from the given date keeping it normalised
# time_subSeconds - subtract seconds from the given date keeping it normalised
#
# SYNOPSIS
#	time_subYears   TIME YEARS
#	time_subMonths  TIME MONTHS
#	time_subDays    TIME DAYS
#	time_subHours   TIME HOURS
#	time_subMinutes TIME MINUTES
#	time_subSeconds TIME SECONDS
#
# DESCRIPTION
#	These functions are simple wrapper functions to time_subtract
#
# OPTIONS
#	TIME
#		A valid array of time.
#
#	YEARS, MONTHS, etc.
#		An integer positive or negative number of years, months, etc..
#
# DIAGNOSTICS
#	These functions return a an array of time that represents a valid date
#   to stdout and set the $return variable.
#
# EXAMPLE
#	t=( 1967 3 20 6 50 0 0 0 )
#	time_subMonths ${t[@]} 42
#
# GLOBAL VARIABLES SET
#	return                             # array holding the result
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.131018===

function time_subYears { # ( TIME YEARS )
	time_add ${@:1:8} $(( 0 - ${9:-0} )) 0 0 0 0 0 0 0
}

function time_subMonths { # ( TIME MONTHS )
	time_add ${@:1:8} 0 $(( 0 - ${9:-0} )) 0 0 0 0 0 0
}

function time_subDays { # ( TIME DAYS )
	time_add ${@:1:8} 0 0 $(( 0 - ${9:-0} )) 0 0 0 0 0
}

function time_subHours { # ( TIME HOURS )
	time_add ${@:1:8} 0 0 0 $(( 0 - ${9:-0} )) 0 0 0 0
}

function time_subMinutes { # ( TIME MINUTES )
	time_add ${@:1:8} 0 0 0 0 $(( 0 - ${9:-0} )) 0 0 0
}

function time_subSeconds { # ( TIME SECONDS )
	time_add ${@:1:8} 0 0 0 0 0 $(( 0 - ${9:-0} )) 0 0
}


#==============================================================================
# time_today - returns the array of time of the current day 0:00:00 in UTC
#
# SYNOPSIS
#	time_today
#
# DESCRIPTION
#	This function returns the array of time of the current day 0:00:00 in UTC
#
# DIAGNOSTICS
#	This function returns the array of time
#
# GLOBAL VARIABLES SET
#	return                             # array, holding the result
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.080915===

function time_today {
	time_parse "$( date -u +"%Y-%m-%d" ) 00:00:00" "YYYY-MM-DD hh:mm:ss"
}


#==============================================================================
# time_tomorrow - returns the array of time of tomorrow 0:00:00 in UTC
#
# SYNOPSIS
#	time_tomorrow
#
# DESCRIPTION
#	This function returns the array of time of tomorrow 0:00:00 in UTC
#
# DIAGNOSTICS
#	This function returns the array of time
#
# GLOBAL VARIABLES SET
#	return                             # array, holding the result
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.080915===
# --!-- ToDo: can be done faster with lib_calendar functions only

function time_tomorrow {
	time_addDays $(time_today) 1
}


#==============================================================================
# time_unserialise - converts a serialised time into an array of time
#
# SYNOPSIS
#	time_unserialise SECONDS MONTHS YEARS
#
# DESCRIPTION
#	This function takes a serialised time in SECONDS MONTHS and YEARS and
#	converts it in an array of TIME.
#
# OPTIONS
#	SECONDS MONTHS YEARS
#		The serialised time.
#
# DIAGNOSTICS
#	This function returns an array of time to stdout.
#
# EXAMPLE
#	time_unserialise 211845207845.678901 0 0
#		This returns ( 2001 1 2 3 4 5 678 901 )
#
# GLOBAL VARIABLES SET
#	return                             # array holding the result
#
# SEE ALSO
#	time_spanUnserialise
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.080630===

function time_unserialise { # SERIALISED_TIME
	local s=$1
	local tmp

	tmp=( $( echo '
		t = '$s'
		u =   t % 0.001 * 1000000   ; t -= u / 1000000
		i = ( t % 1     ) * 1000    ; t -= i / 1000
		s = ( t % 60    )           ; t -= s
		m = ( t % 3600  )  / 60     ; t -= m * 60
		h = ( t % 86400 ) / 3600    ; t -= h * 3600
		d = t / 86400
		d ; h ; m ; s ; i ; u' | bc ) )

	return=( $( calendar_sdnToGregorian ${tmp[0]%%.*} ) ${tmp[1]%%.*} ${tmp[2]%%.*} $(( ${tmp[3]%%.*} + 0 )) $(( ${tmp[4]%%.*} + 0 )) ${tmp[5]%%.*} )
	echo "${return[@]}"
}

function time_unserialize { time_unserialise $@ ; }   # alias


#==============================================================================
# time_yesterday - returns the array of time of yesterday 0:00:00 in UTC
#
# SYNOPSIS
#	time_yesterday
#
# DESCRIPTION
#	This function returns the array of time of yesterday 0:00:00 in UTC
#
# DIAGNOSTICS
#	This function returns the array of time
#
# GLOBAL VARIABLES SET
#	return                             # array, holding the result
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.080915===
# --!-- TODO: can be done faster with lib_calendar functions only

function time_yesterday {
	time_subDays $(time_today) 1
}

###############################################################################
# Cleanup and return
###############################################################################

declare -fr time_add
declare -fr time_addDays
declare -fr time_addHours
declare -fr time_addMinutes
declare -fr time_addMonths
declare -fr time_addSeconds
declare -fr time_addYears
declare -fr time_compare
declare -fr time_convert
declare -fr time_diff
declare -fr time_getMonth
declare -fr time_getMonthName
declare -fr time_getYear
declare -fr time_normalise
declare -fr time_normalize
declare -fr time_now
declare -fr time_parse
declare -fr time_pduCycle
declare -fr time_printf
declare -fr time_serialise
declare -fr time_serialize
declare -fr time_setDate
declare -fr time_setDay
declare -fr time_setHour
declare -fr time_setMinute
declare -fr time_setMonth
declare -fr time_setSecond
declare -fr time_setTime
declare -fr time_setYear
declare -fr time_spanAdd
declare -fr time_spanMultiply
declare -fr time_spanNegate
declare -fr time_spanSerialise
declare -fr time_spanSerialize
declare -fr time_spanSubtract
declare -fr time_spanUnserialise
declare -fr time_spanUnserialize
declare -fr time_subDays
declare -fr time_subHours
declare -fr time_subMinutes
declare -fr time_subMonths
declare -fr time_subSeconds
declare -fr time_subYears
declare -fr time_subtract
declare -fr time_today
declare -fr time_tomorrow
declare -fr time_unserialise
declare -fr time_unserialize
declare -fr time_yesterday

readonly time_lib_loaded=1
return $ERR_NOERR

###############################################################################
# END
###############################################################################
# TODO: check perl module EPSTime.pm for needed time formats
###############################################################################
