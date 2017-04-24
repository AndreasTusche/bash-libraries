#
# NAME
#
#	lib_calendar - a bash functions library for calendar calculations
#
# SYNOPSIS
#
#	source lib_calendar.bash
#
# DESCRIPTION
#
#	This library provides functions for calendar calculations:
#
#	calendar_dayOfWeek      - convert a SDN to a day-of-week number
#	calendar_doyToGregorian - convert day of year to Gregorian date
#	calendar_gregorianToDoy - convert Gregorian date to day of year
#	calendar_gregorianToSdn - convert Gregorian date to SDN
#	calendar_html           - output Gregorian calendar in html using a table
#	calendar_julianToSdn    - convert Julian date to SDN
#	calendar_sdnToGregorian - convert SDN to Gregorian date
#	calendar_sdnToJulian    - convert SDN to Julian date
#
#	Additionally this library provides some arrays:
#
#	calendar_dayName
#	calendar_dayNameShort
#	calendar_gregorianMonthName
#	calendar_gregorianMonthNameShort
#
# THE SERIAL DAY NUMBER
#
#     This library defines a set of routines that convert calendar dates to
#     and from a serial day number (SDN).  The SDN is a serial numbering of
#     days where SDN 1 is November 25, 4714 BC in the Gregorian calendar and
#     SDN 2447893 is January 1, 1990.  This system of day numbering is
#     sometimes referred to as Julian days, but to avoid confusion with the
#     Julian calendar, it is referred to as serial day numbers here.  The term
#     Julian days is also used to mean the number of days since the beginning
#     of the current year.
#
#     The SDN can be used as an intermediate step in converting from one
#     calendar system to another (such as Gregorian to Jewish).  It can also
#     be used for date computations such as easily comparing two dates,
#     determining the day of the week, finding the date of yesterday or
#     calculating the number of days between two dates.
#
#     For each calendar, there are two routines provided.  One converts dates
#     in that calendar to SDN and the other converts SDN to calendar dates.
#     The routines are named calendar_sdnTo<CALENDAR>() and
#     calendar_<CALENDAR>ToSdn(), where <CALENDAR> is the name of the calendar
#     system.
#
#     SDN values less than one are not supported.  If a conversion routine
#     returns an SDN of zero, this means that the date given is either invalid
#     or is outside the supported range for that calendar.
#
#     At least some validity checks are performed on input dates.  For
#     example, a negative month number will result in the return of zero for
#     the SDN.  A returned SDN greater than one does not necessarily mean that
#     the input date was valid.  To determine if the date is valid, convert it
#     to SDN, and if the SDN is greater than zero, convert it back to a date
#     and compare to the original.
#
# JULIAN CALENDAR
#
#      VALID RANGE
#
#      4713 Before Christ to at least 10000 Anno Domini
#
#      Although this software can handle dates all the way back to 4713
#      B.C., such use may not be meaningful.  The calendar was created in
#      46 B.C., but the details did not stabilize until at least 8 A.D.,
#      and perhaps as late at the 4th century.  Also, the beginning of a
#      year varied from one culture to another - not all accepted January
#      as the first month.
#
#      CALENDAR OVERVIEW
#
#      Julius Caesar created the calendar in 46 B.C. as a modified form of
#      the old Roman republican calendar which was based on lunar cycles.
#      The new Julian calendar set fixed lengths for the months, abandoning
#      the lunar cycle.  It also specified that there would be exactly 12
#      months per year and 365.25 days per year with every 4th year being a
#      leap year.
#
#      Note that the current accepted value for the tropical year is
#      365.242199 days, not 365.25.  This lead to an 11 day shift in the
#      calendar with respect to the seasons by the 16th century when the
#      Gregorian calendar was created to replace the Julian calendar.
#
#      The difference between the Julian and today's Gregorian calendar is
#      that the Gregorian does not make centennial years leap years unless
#      they are a multiple of 400, which leads to a year of 365.2425 days.
#      In other words, in the Gregorian calendar, 1700, 1800 and 1900 are
#      not leap years, but 2000 is.  All centennial years are leap years in
#      the Julian calendar.
#
#      The details are unknown, but the lengths of the months were adjusted
#      until they finally stabilised in 8 A.D. with their current lengths:
#
#          January          31
#          February         28/29
#          March            31
#          April            30
#          May              31
#          June             30
#          Quintilis/July   31
#          Sextilis/August  31
#          September        30
#          October          31
#          November         30
#          December         31
#
#      In the early days of the calendar, the days of the month were not
#      numbered as we do today.  The numbers ran backwards (decreasing) and
#      were counted from the Ides (15th of the month - which in the old
#      Roman republican lunar calendar would have been the full moon) or
#      from the Nonae (9th day before the Ides) or from the beginning of
#      the next month.
#
#      In the early years, the beginning of the year varied, sometimes
#      based on the ascension of rulers.  It was not always the first of
#      January.
#
#      Also, today's epoch, 1 A.D. or the birth of Jesus Christ, did not
#      come into use until several centuries later when Christianity became
#      a dominant religion.
#
#      ALGORITHMS
#
#      The calculations are based on two different cycles: a 4 year cycle
#      of leap years and a 5 month cycle of month lengths.
#
#      The 5 month cycle is used to account for the varying lengths of
#      months.  You will notice that the lengths alternate between 30 and
#      31 days, except for three anomalies: both July and August have 31
#      days, both December and January have 31, and February is less than
#      30.  Starting with March, the lengths are in a cycle of 5 months
#      (31, 30, 31, 30, 31):
#
#          Mar   31 days  \
#          Apr   30 days   \
#          May   31 days    > First cycle
#          Jun   30 days   |
#          Jul   31 days  /
#
#          Aug   31 days  \
#          Sep   30 days   \
#          Oct   31 days    > Second cycle
#          Nov   30 days   |
#          Dec   31 days  /
#
#          Jan   31 days  \
#          Feb 28/9 days   \
#                           > Third cycle (incomplete)
#
#      For this reason the calculations (internally) assume that the year
#      starts with March 1.
#
# GREGORIAN CALENDAR
#
#      VALID RANGE
#
#      4714 Before Christ to at least 10000 Anno Domini
#
#      The Gregorian calendar was not instituted until October 15, 1582 (or
#      October 5, 1582 in the Julian calendar).  Some countries did not accept
#      it until much later.  For example, Britain converted in 1752, the USSR
#      in 1918, Turkey in 1927 and China 1929. Additionally different states
#      within a country accepted it on different dates. Most European countries
#      used the Julian calendar prior to the Gregorian.
#
#      OVERVIEW
#
#      The Gregorian calendar is a modified version of the Julian calendar.
#      The only difference being the specification of leap years.  The
#      Julian calendar specifies that every year that is a multiple of 4
#      will be a leap year.  This leads to a year that is 365.25 days long,
#      but the current accepted value for the tropical year is 365.242199
#      days.
#
#      To correct this error in the length of the year and to bring the
#      vernal equinox back to March 21, Pope Gregory XIII issued a papal
#      bull declaring that Thursday October 4, 1582 would be followed by
#      Friday October 15, 1582 and that centennial years would only be a
#      leap year if they were a multiple of 400.  This shortened the year
#      by 3 days per 400 years, giving a year of 365.2425 days.
#
#      Another recently proposed change in the leap year rule is to make
#      years that are multiples of 4000 not a leap year, but this has never
#      been officially accepted and this rule is not implemented in these
#      algorithms.
#
#      ALGORITHMS
#
#      The calculations are based on three different cycles: a 400 year
#      cycle of leap years, a 4 year cycle of leap years and a 5 month
#      cycle of month lengths.
#
# BUGS
#
#     Do not use this software on 16 bit systems. The SDNs will not fit in the
#     16 bits that some systems allocate to an integer.
#
# AUTHOR
#	Conversions Between Calendar Date and Julian Day Number by Robert J.
#	Tantzen, Communications of the Association for Computing Machinery
#	August 1963.  (Also published in Collected Algorithms from CACM,
#	algorithm number 199).
#
#	SDN calculations (c) 1993-1995 by Scott E. Lee.
#
#	@author     Andreas Tusche (bash-libraries@andreas-tusche.de)
#	@copyright  (c) 2008, Andreas Tusche, <http://www.andreas-tusche.de/>
#	@package    bash_libraries
#	@version    $Revision: 0.0 $
#	@(#) $Id: . Exp $
#
# 2008-03-20 AnTu initial release

(( ${calendar_lib_loaded:-0} )) && return 0 # load me only once

###############################################################################
# config
###############################################################################

# general global variables
calendar_DEBUG=${DEBUG:-0}             # no debugging by default
calendar_VERBOSE=${VERBOSE:-0}         # verbose defaults to FALSE

# Convert a day-of-week number (0 to 6), as returned from calendar_dayOfWeek(),
# to the name of the day
readonly -a calendar_dayName=( "Sunday" "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" )

# Convert a day-of-week number (0 to 6), as returned from calendar_dayOfWeek(),
# to the abbreviated (three character) name of the day.
readonly -a calendar_dayNameShort=( "Sun" "Mon" "Tue" "Wed" "Thu" "Fri" "Sat" )

# Convert a Gregorian month number (1 to 12) to the name of the Gregorian
# month.
readonly -a calendar_gregorianMonthName=( "_" "January" "February" "March" "April" "May" "June" "July" "August" "September" "October" "November" "December" )
readonly -a calendar_gregorianMONTHName=( "_" "JANUARY" "FEBRUARY" "MARCH" "APRIL" "MAY" "JUNE" "JULY" "AUGUST" "SEPTEMBER" "OCTOBER" "NOVEMBER" "DECEMBER" )

# Convert a Gregorian month number (1 to 12) to the abbreviated (three
# character) name of the Gregorian month.
readonly -a calendar_gregorianMonthNameShort=( "_" "Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec" )
readonly -a calendar_gregorianMONTHNameShort=( "_" "JAN" "FEB" "MAR" "APR" "MAY" "JUN" "JUL" "AUG" "SEP" "OCT" "NOV" "DEC" )

# misc
readonly calendar_DAYS_PER_4_YEARS=1461
readonly calendar_DAYS_PER_400_YEARS=146097
readonly calendar_DAYS_PER_5_MONTHS=153
readonly calendar_GREGOR_SDN_OFFSET=32045    # Gregorian
readonly calendar_JULIAN_SDN_OFFSET=32083    # Julian

# general global constants
readonly calendar_MY_VERSION='$Revision: 1.0 $' # version of this library

# use error codes beween 3 and 125 (the others are reserved by bash)
readonly calendar_ERR_NOERR=${ERR_NOERR:-0}      # normal exit status, no error
readonly calendar_ERR_OUT_OF_RANGE=${ERR_OUT_OF_RANGE:-45}  # Warning, values out of range

###############################################################################
# all arguments are handled by the calling script, but in case help is needed
###############################################################################

if [[ "${0##*/}" == "lib_calendar.bash" && "$1" == "--help" ]] ; then
	awk '/^# NAME/,/^#===|^####/ {print l;sub(/^# ?/,"",$0);l=$0}' "${0%/*}/${0##*/}"
	exit
fi

###############################################################################
# Functions
###############################################################################

#==============================================================================
# calendar_dayOfWeek - Convert a SDN to a day-of-week number
#
# SYNOPSIS
#	calendar_dayOfWeek SERIALDAYNUMBER
#
# DESCRIPTION
#	Convert a SDN to a day-of-week number (0 to 6).  Where 0 stands for
#   Sunday, 1 for Monday, etc. and 6 stands for Saturday.
#	This function is meant to be used with dates from the Gregorian calendar.
#
# OPTIONS
#	SERIALDAYNUMBER
#       serial day number
#
# DIAGNOSTICS
#	This function returns 0 if everything went well
#
# EXAMPLE
#	sdn=$( calendar_gregorianToSdn 1967 3 20 )   # returns 2439570
#	dow=$( calendar_dayOfWeek $sdn )             # returns 1
#	echo ${calendar_dayName[$dow]}               # returns Monday
#
# GLOBAL VARIABLES SET
#	return                             # integer holding the result
#
# AUTHOR
#     Written by Andreas Tusche bash-libraries@andreas-tusche.de>
#===================================================================V.131002===

function calendar_dayOfWeek { # SERIALDAYNUMBER
	# parameter(s) to function
	local sdn=${1:-0}

	# variables local
	local -i dow

	dow=$(( ( sdn + 1 ) % 7 ))

	# return values
	if (( $dow >= 0 )) ; then
		return=$dow
	else
		return=$(( dow + 7 ))
	fi

	echo "${return}"
}

#==============================================================================
# calendar_doyToGregorian - convert day of year number to Gregorian date
#
# SYNOPSIS
#	calendar_doyToGregorian YEAR DOY
#
# DESCRIPTION
#   This translates a year and day of year into a Gregorian date.
#
# OPTIONS
#	YEAR
#        An integer value giving the (Gregorian) year.
#
#	DOY
#		An integer value of the day of the YEAR
#
# DIAGNOSTICS
#	This function returns the result in a global array
#   $return = ( year month date )
#
# EXAMPLE
#	calendar_doyToGregorian 1967 79
#        This sets $return to ( 1967 3 20 )
#
# GLOBAL VARIABLES SET
#	return                             # array holding the result
#
# AUTHOR
#     Written by Andreas Tusche bash-libraries@andreas-tusche.de>
#===================================================================V.080502===

function calendar_doyToGregorian { # YEAR DOY
	local y=$1 d=$2
	if (( ${#@} < 2 )) ; then
		y=$( date -u +"%Y" )
		d=$1
	fi
	calendar_sdnToGregorian $(( $(calendar_gregorianToSdn $y 1 1)  + $d - 1 ))
}

#==============================================================================
# calendar_gregorianToDoy - convert Gregorian date to day of year
#
# SYNOPSIS
#	calendar_gregorianToDoy YEAR MONTH DAY
#
# DESCRIPTION
#	This function converts a Gregorian date to a day of year.
#
# OPTIONS
#	YEAR MONTH DAY
#		Integer values of the year, month and day
#
# DIAGNOSTICS
#	This function returns the result in the global variable $return
#
# EXAMPLE
#	calendar_gregorianToDoy 1967 3 20
#        This results in 79
#
# GLOBAL VARIABLES SET
#	return                             # integer holding the result
#
# AUTHOR
#     Written by Andreas Tusche bash-libraries@andreas-tusche.de>
#===================================================================V.080502===

function calendar_gregorianToDoy { # YEAR MONTH DAY
	return=$(( $(calendar_gregorianToSdn $1 $2 $3) - $(calendar_gregorianToSdn $1 1 1) + 1))
	echo "${return}"
}

#==============================================================================
# calendar_gregorianToSdn - convert Gregorian date to serial day number
#
# SYNOPSIS
#	calendar_gregorianToSdn YEAR MONTH DAY
#
# DESCRIPTION
#	This function converts a Gregorian date to a serial day number.
#   Zero is returned when the input date is detected as invalid or out of the
#   supported range.  The return value will be > 0 for all valid, supported
#   dates, but there are some invalid dates that will return a positive value.
#   To verify that a date is valid, convert it to SDN and then back and compare
#   with the original.
#
# OPTIONS
#	YEAR MONTH DAY
#		Integer numbers for year month and day
#
# DIAGNOSTICS
#	This function returns the result in the global variable $return
#
# EXAMPLE
#	calendar_gregorianToSdn 1967 3 20
#        This results in 2439570
#
# GLOBAL VARIABLES USED
#   calendar_DAYS_PER_4_YEARS
#   calendar_DAYS_PER_400_YEARS
#   calendar_DAYS_PER_5_MONTHS
#   calendar_GREGOR_SDN_OFFSET
#
# GLOBAL VARIABLES SET
#	return                             # integer holding the result
#
# AUTHOR
#     Written by Andreas Tusche bash-libraries@andreas-tusche.de>
#===================================================================V.080403===

function calendar_gregorianToSdn { # YEAR MONTH DAY
	# parameter(s) to function
	local inputYear=${1:-0}
	local inputMonth=${2:-0}
	local inputDay=${3:-0}

	# variables local
	local -i year month

	# check for invalid dates
	if (( $inputYear == 0 || $inputYear < -4714 || $inputMonth <= 0 || $inputMonth > 12 || $inputDay <= 0 || $inputDay > 31 )) ; then
		return=0
		echo "${return}"
		return $calendar_ERR_OUT_OF_RANGE
	fi

	# check for dates before SDN 1 (Nov 25, 4714 B.C.)
	if (( $inputYear == -4714 )) ; then
		if (( $inputMonth < 11 || ( $inputMonth == 11 && $inputDay < 25 ) )) ; then
			return=0
			echo "${return[@]}"
			return $calendar_ERR_OUT_OF_RANGE
		fi
	fi

	# Make year always a positive number
	if (( $inputYear < 0 )) ; then
		(( year = inputYear + 4801 ))
	else
		(( year = inputYear + 4800 ))
	fi

	# Adjust the start of the year
	if (( $inputMonth > 2 )) ; then
		(( month = inputMonth - 3 ))
	else
		(( month = inputMonth + 9 , year-- ))
	fi

	# return values
	return=$(( ( ( ( year / 100 ) * calendar_DAYS_PER_400_YEARS ) / 4 + ( ( year % 100 ) * calendar_DAYS_PER_4_YEARS ) / 4 + ( month * calendar_DAYS_PER_5_MONTHS + 2 ) / 5 + inputDay - calendar_GREGOR_SDN_OFFSET ) ))
	echo "${return}"
}

#==============================================================================
# calendar_html - output Gregorian calendar in html using a table
#
# SYNOPSIS
#	calendar_html [ YEAR MONTH [ PAGE_PREFIX PAGE_SUFFIX ]]
#
# DESCRIPTION
#	This functions reformats the output of the Unix cal command to HTML.
#	The first line (containing the month and the year) and all empty lines
#	are skipped in the output.
#
# OPTIONS
#	YEAR MONTH
#		The Gregorian year and month as integer numbers. Defaults to
#		this year and month.
#	PAGE_PREFIX PAGE_SUFFIX
#		Every day is linked to an html page whose name starts with
#		PAGE_PREFIX. Then the (two-digits) day number is appended and then the
#		PAGE_SUFFIX. They default to "page_" and ".html"
# EXAMPLE
#	calendar_html 1967 3 "1967_" ".html"
#
# AUTHOR
#	Andreas Tusche (lib_calendar@andreas-tusche.de) 
#===================================================================V.081111===

function calendar_html { # [ YEAR MONTH [ PAGE_PREFIX PAGE_SUFFIX ]]
	year=${1:-$( date +%Y )}   # year defaults to this year
	month=${2:-$( date +%m )}  # month defaults to this month
	page=${3:-"page_"}         # prefix to file name of linked pages
	pageext=${4:-".html"}      # suffix of file name of linked pages

	local awkCal2Html='
		BEGIN {
			id      = "cal"
			page    = "'$page'"
			pageext = "'$pageext'"

			print "<table id=\"" id "\">"
		}

		NF == 0 {
			next
		}

		NR < 2 {
			next
		}

		NR >= 2 {
			printf "<tr class=\"" id "\">"
		}

		NR == 2 {
			for (i=1; i<=7; i++) {
				printf "<td class=\"" id "day\">" $i "</td>"
			}
		}

		NR == 3 {
			for (i=0; i<(7-NF); i++) {
				printf "<td class=\"" id "0\">&nbsp;</td>"
			}
		}

		NR > 2  {
			for (i=1; i<=NF; i++) {
				printf "<td id=\"" id $i "\"><a href=\"" page "%.2d" pageext "\">" $i "</a></td>" , $i
			}
		}

		NR > 6  {
			for (i=0; i<(7-NF); i++) {
				printf "<td class=\"" id "0\">&nbsp;</td>"
			}
		}

		NR >= 2  {
			print "</tr>"
		}

		END     {
			print "</table>"
		}
'

	cal $month $year | awk "$awkCal2Html"
}

#==============================================================================
# calendar_julianToSdn - convert Julian date to serial day number
#
# SYNOPSIS
#	calendar_julianToSdn YEAR MONTH DAY
#
# DESCRIPTION
#
# OPTIONS
#	YEAR MONTH DAY
#		The Julian year, month and day as integer numbers.
#
# DIAGNOSTICS
#	This function returns the result in the global variable $return
#
# EXAMPLE
#	calendar_julianToSdn 1990 1 1
#        This results in 2447906
#
# GLOBAL VARIABLES USED
#   calendar_DAYS_PER_4_YEARS
#   calendar_DAYS_PER_5_MONTHS
#   calendar_JULIAN_SDN_OFFSET
#
# GLOBAL VARIABLES SET
#	return                             # integer holding the result
#
# AUTHOR
#     Written by Andreas Tusche bash-libraries@andreas-tusche.de>
#===================================================================V.080403===

function calendar_julianToSdn { # YEAR MONTH DAY
	# parameter(s) to function
	local inputYear=${1:-0}
	local inputMonth=${2:-0}
	local inputDay=${3:-0}

	# variables local
	local -i year month

	# check for invalid dates
	if (( $inputYear == 0 || $inputYear < -4713 || $inputMonth <= 0 || $inputMonth > 12 || $inputDay <= 0 || $inputDay > 31 )) ; then
		return=0
		echo "${return}"
		return $calendar_ERR_OUT_OF_RANGE
	fi

	# check for dates before SDN 1 (Jan 2, 4713 B.C.)
	if (( $inputYear == -4713 )) ; then
		if (( $inputMonth == 1 && $inputDay == 1 )) ; then
			return=0
			echo "${return[@]}"
			return $calendar_ERR_OUT_OF_RANGE
		fi
	fi

	# Make year always a positive number
	if (( $inputYear < 0 )) ; then
		(( year = inputYear + 4801 ))
	else
		(( year = inputYear + 4800 ))
	fi

	# Adjust the start of the year
	if (( inputMonth > 2 )) ; then
		(( month = inputMonth - 3 ))
	else
		(( month = inputMonth + 9 ,  year-- ))
	fi

	# return values
	return=$(( ( year * calendar_DAYS_PER_4_YEARS) / 4 + (month * calendar_DAYS_PER_5_MONTHS + 2) / 5 + inputDay - calendar_JULIAN_SDN_OFFSET ))
	echo "${return[@]}"
}

#==============================================================================
# calendar_sdnToGregorian () - convert serial day number to Gregorian date
#
# SYNOPSIS
#	calendar_sdnToGregorian SERIALDAYNUMBER
#
# DESCRIPTION
#   If the input serial day number (SDN) is less than 1, the three output
#   values will all be set to zero, otherwise year will be >= -4714 and != 0;
#   month will be in the range 1 to 12 inclusive; day will be in the range 1 to
#   31 inclusive.
#
# OPTIONS
#	SERIALDAYNUMBER
#        The serial day number (SDN). The SDN is a serial numbering of days
#        where SDN 1 is November 25, 4714 BC in the Gregorian calendar and
#        SDN 2447893 is January 1, 1990.
#
# DIAGNOSTICS
#	This function returns the result in a global array
#   $return = ( year month date )
#
# EXAMPLE
#	calendar_sdnToGregorian 2447893
#        This sets $return to ( 1990 1 1 )
#
# GLOBAL VARIABLES USED
#   calendar_DAYS_PER_4_YEARS
#   calendar_DAYS_PER_400_YEARS
#   calendar_DAYS_PER_5_MONTHS
#   calendar_GREGOR_SDN_OFFSET
#
# GLOBAL VARIABLES SET
#	return                             # array holding the result
#
# AUTHOR
#     Written by Andreas Tusche bash-libraries@andreas-tusche.de>
#===================================================================V.080403===

function calendar_sdnToGregorian { # SERIALDAYNUMBER
	# parameter(s) to function
	local sdn=${1:-0}

	# variables local
	local -i century year month day temp dayOfYear

	if (( $sdn <= 0 )) ; then
		return=( 0 0 0 )
		echo "${return[@]}"
		return $calendar_ERR_OUT_OF_RANGE
	fi

	temp=$(( ( sdn + calendar_GREGOR_SDN_OFFSET ) * 4 - 1 ))

	if (( $temp < 0 )) ; then
		return=( 0 0 0 )
		echo "${return[@]}"
		return $calendar_ERR_OUT_OF_RANGE
	fi

	# Calculate the century (year/100)
	#           the year and day of year (1 <= dayOfYear <= 366)
	#           the month and day of month
	((
		century = temp / calendar_DAYS_PER_400_YEARS ,

		temp = ((temp % calendar_DAYS_PER_400_YEARS) / 4) * 4 + 3 ,
		year = (century * 100) + (temp / calendar_DAYS_PER_4_YEARS) ,
		dayOfYear = (temp % calendar_DAYS_PER_4_YEARS) / 4 + 1 ,

		temp = dayOfYear * 5 - 3 ,
		month = temp / calendar_DAYS_PER_5_MONTHS ,
		day = (temp % calendar_DAYS_PER_5_MONTHS) / 5 + 1
	))

	# Convert to the normal beginning of the year
	if (( $month < 10 )) ; then
		(( month += 3 ))
	else
		(( year += 1 , month -= 9 ))
	fi

	# Adjust to the B.C./A.D. type numbering
	(( year -= 4800 ))

	if (( $year <= 0 )) ; then
		(( year-- ))
	fi

	# return values
	return=( $year $month $day )
	echo "${return[@]}"
}

#==============================================================================
# calendar_sdnToJulian () - convert serial day number to Julian date
#
# SYNOPSIS
#	calendar_sdnToJulian SERIALDAYNUMBER
#
# DESCRIPTION
#   If the input serial day number (SDN) is less than 1, the three output
#   values will all be set to zero, otherwise year will be >= -4713 and != 0;
#   month will be in the range 1 to 12 inclusive; day will be in the range 1 to
#   31 inclusive.
#
# OPTIONS
#	SERIALDAYNUMBER
#        The serial day number (SDN). The SDN is a serial numbering of days
#        where SDN 1 is November 25, 4714 BC in the Gregorian calendar and
#        SDN 2447893 is January 1, 1990.
#
# DIAGNOSTICS
#	This function returns the result in a global array
#   $return = ( year month date )
#
# EXAMPLE
#	calendar_sdnToJulian 2447893
#        This sets $return to ( -?- -?- -?- )
#
# GLOBAL VARIABLES USED
#   calendar_DAYS_PER_4_YEARS
#   calendar_DAYS_PER_400_YEARS
#   calendar_DAYS_PER_5_MONTHS
#   calendar_JULIAN_SDN_OFFSET
#
# GLOBAL VARIABLES SET
#	return                             # array holding the result
#
# AUTHOR
#     Written by Andreas Tusche bash-libraries@andreas-tusche.de>
#===================================================================V.080403===

function calendar_sdnToJulian { # SERIALDAYNUMBER
	# parameter(s) to function
	local sdn=${1:-0}

	# variables local
	local -i year month day temp dayOfYear

	if (( $sdn <= 0 )) ; then
		return=( 0 0 0 )
		echo "${return[@]}"
		return $calendar_ERR_OUT_OF_RANGE
	fi

	temp=$(( ( sdn + calendar_JULIAN_SDN_OFFSET ) * 4 - 1 ))

	# Calculate the year and day of year (1 <= dayOfYear <= 366)
	#           the month and day of month
	((
		year = temp / calendar_DAYS_PER_4_YEARS ,
		dayOfYear = (temp % calendar_DAYS_PER_4_YEARS) / 4 + 1 ,

		temp = dayOfYear * 5 - 3 ,
		month = temp / calendar_DAYS_PER_5_MONTHS ,
		day = (temp % calendar_DAYS_PER_5_MONTHS) / 5 + 1
	))

	# Convert to the normal beginning of the year
	if (( $month < 10 )) ; then
		(( month += 3 ))
	else
		(( year++ , month -= 9 ))
	fi

	# Adjust to the B.C./A.D. type numbering
	(( year -= 4800 ))
	if (( $year <= 0 )) ; then
		(( year-- ))
	fi

	# return values
	return=( $year $month $day )
	echo "${return[@]}"
}

###############################################################################
# Clean-up and return
###############################################################################

declare -Fr calendar_dayOfWeek
declare -Fr calendar_doyToGregorian
declare -Fr calendar_gregorianToSdn
declare -Fr calendar_gregorianToDoy
declare -Fr calendar_html
declare -Fr calendar_julianToSdn
declare -Fr calendar_sdnToGregorian
declare -Fr calendar_sdnToJulian

readonly calendar_lib_loaded=1
return $calendar_ERR_NOERR

###############################################################################
# END
###############################################################################
# @ ToDo return correct error values
# @ ToDo add a self test function (test e.g. if month and day of "09" is not octal)
# @ ToDo new function calendar_isLeapYear()
# @ ToDo new function calendar_getCentury()
# @ ToDo new function calendar_getNumberOfDays() - for years or months
# @ ToDo new function calendar_getMonthName()
# @ ToDo new function calendar_getWeekDayName()
# @ ToDo new function calendar_getBeginDST()
# @ ToDo new function calendar_getEndDST()
###############################################################################
