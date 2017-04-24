# bash libraries

My small collection of functions for the bash shell. When sourcing a library, it provides the functions to the executing shell.

	source lib_<mylibrary>.bash


##	lib_array

	source lib_array.bash

This library provides functions for array handling:

	array_reverse() - reverses an array
	array_shift()   - shifts array elements
	array_sort()    - sorts array elements

## lib_calendar

	source lib_calendar.bash

This library provides functions for calendar calculations:

	calendar_dayOfWeek      - convert a SDN to a day-of-week number
	calendar_doyToGregorian - convert day of year to Gregorian date
	calendar_gregorianToDoy - convert Gregorian date to day of year
	calendar_gregorianToSdn - convert Gregorian date to SDN
	calendar_html           - output Gregorian calendar in html using a table
	calendar_julianToSdn    - convert Julian date to SDN
	calendar_sdnToGregorian - convert SDN to Gregorian date
	calendar_sdnToJulian    - convert SDN to Julian date

Additionally this library provides some arrays:

	calendar_dayName
	calendar_dayNameShort
	calendar_gregorianMonthName
	calendar_gregorianMonthNameShort

### THE SERIAL DAY NUMBER

This library defines a set of routines that convert calendar dates to
and from a serial day number (SDN).  The SDN is a serial numbering of
days where SDN 1 is November 25, 4714 BC in the Gregorian calendar and
SDN 2447893 is January 1, 1990.  This system of day numbering is
sometimes referred to as Julian days, but to avoid confusion with the
Julian calendar, it is referred to as serial day numbers here.  The term
Julian days is also used to mean the number of days since the beginning
of the current year.

The SDN can be used as an intermediate step in converting from one
calendar system to another (such as Gregorian to Jewish).  It can also
be used for date computations such as easily comparing two dates,
determining the day of the week, finding the date of yesterday or
calculating the number of days between two dates.

For each calendar, there are two routines provided.  One converts dates
in that calendar to SDN and the other converts SDN to calendar dates.
The routines are named calendar_sdnTo<CALENDAR>() and
calendar_<CALENDAR>ToSdn(), where <CALENDAR> is the name of the calendar
system.

SDN values less than one are not supported.  If a conversion routine
returns an SDN of zero, this means that the date given is either invalid
or is outside the supported range for that calendar.

At least some validity checks are performed on input dates.  For
example, a negative month number will result in the return of zero for
the SDN.  A returned SDN greater than one does not necessarily mean that
the input date was valid.  To determine if the date is valid, convert it
to SDN, and if the SDN is greater than zero, convert it back to a date
and compare to the original.

### JULIAN CALENDAR

#### VALID RANGE

4713 Before Christ to at least 10000 Anno Domini

Although this software can handle dates all the way back to 4713
B.C., such use may not be meaningful.  The calendar was created in
46 B.C., but the details did not stabilize until at least 8 A.D.,
and perhaps as late at the 4th century.  Also, the beginning of a
year varied from one culture to another - not all accepted January
as the first month.

#### CALENDAR OVERVIEW

Julius Caesar created the calendar in 46 B.C. as a modified form of
the old Roman republican calendar which was based on lunar cycles.
The new Julian calendar set fixed lengths for the months, abandoning
the lunar cycle.  It also specified that there would be exactly 12
months per year and 365.25 days per year with every 4th year being a
leap year.

Note that the current accepted value for the tropical year is
365.242199 days, not 365.25.  This lead to an 11 day shift in the
calendar with respect to the seasons by the 16th century when the
Gregorian calendar was created to replace the Julian calendar.

The difference between the Julian and today's Gregorian calendar is
that the Gregorian does not make centennial years leap years unless
they are a multiple of 400, which leads to a year of 365.2425 days.
In other words, in the Gregorian calendar, 1700, 1800 and 1900 are
not leap years, but 2000 is.  All centennial years are leap years in
the Julian calendar.

The details are unknown, but the lengths of the months were adjusted
until they finally stabilised in 8 A.D. with their current lengths:

	January          31
	February         28/29
	March            31
	April            30
	May              31
	June             30
	Quintilis/July   31
	Sextilis/August  31
	September        30
	October          31
	November         30
	December         31

In the early days of the calendar, the days of the month were not
numbered as we do today.  The numbers ran backwards (decreasing) and
were counted from the Ides (15th of the month - which in the old
Roman republican lunar calendar would have been the full moon) or
from the Nonae (9th day before the Ides) or from the beginning of
the next month.

In the early years, the beginning of the year varied, sometimes
based on the ascension of rulers.  It was not always the first of
January.

Also, today's epoch, 1 A.D. or the birth of Jesus Christ, did not
come into use until several centuries later when Christianity became
a dominant religion.

#### ALGORITHMS

The calculations are based on two different cycles: a 4 year cycle
of leap years and a 5 month cycle of month lengths.

The 5 month cycle is used to account for the varying lengths of
months.  You will notice that the lengths alternate between 30 and
31 days, except for three anomalies: both July and August have 31
days, both December and January have 31, and February is less than
30.  Starting with March, the lengths are in a cycle of 5 months
(31, 30, 31, 30, 31):

	Mar   31 days  \
	Apr   30 days   \
	May   31 days    > First cycle
	Jun   30 days   |
	Jul   31 days  /

	Aug   31 days  \
	Sep   30 days   \
	Oct   31 days    > Second cycle
	Nov   30 days   |
	Dec   31 days  /

	Jan   31 days  \
	Feb 28/9 days   \
	                 > Third cycle (incomplete)

For this reason the calculations (internally) assume that the year
starts with March 1.

### GREGORIAN CALENDAR

#### VALID RANGE

4714 Before Christ to at least 10000 Anno Domini

The Gregorian calendar was not instituted until October 15, 1582 (or
October 5, 1582 in the Julian calendar).  Some countries did not accept
it until much later.  For example, Britain converted in 1752, the USSR
in 1918, Turkey in 1927 and China 1929. Additionally different states
within a country accepted it on different dates. Most European countries
used the Julian calendar prior to the Gregorian.

#### OVERVIEW

The Gregorian calendar is a modified version of the Julian calendar.
The only difference being the specification of leap years.  The
Julian calendar specifies that every year that is a multiple of 4
will be a leap year.  This leads to a year that is 365.25 days long,
but the current accepted value for the tropical year is 365.242199
days.

To correct this error in the length of the year and to bring the
vernal equinox back to March 21, Pope Gregory XIII issued a papal
bull declaring that Thursday October 4, 1582 would be followed by
Friday October 15, 1582 and that centennial years would only be a
leap year if they were a multiple of 400.  This shortened the year
by 3 days per 400 years, giving a year of 365.2425 days.

Another recently proposed change in the leap year rule is to make
years that are multiples of 4000 not a leap year, but this has never
been officially accepted and this rule is not implemented in these
algorithms.

#### ALGORITHMS

The calculations are based on three different cycles: a 400 year
cycle of leap years, a 4 year cycle of leap years and a 5 month
cycle of month lengths.

### BUGS

Do not use this software on 16 bit systems. The SDNs will not fit in the
16 bits that some systems allocate to an integer.



## lib_common

	source lib_common.bash [--help]

This library provides a collection of functions that are common to a
number of scripts and don't fit into one of the other libraries.
The functions of this library are not prefixed by the library identifier
'common_' but have speaking names.

	enum              - enumerate a list of strings and create variables
	rotateLog         - rotate log files and keep n copies 
	printDebug        - print coloured debug message to stderr
	printDebug2       - print indented coloured debug message to stderr
	printError        - print coloured error message to stderr
	printError2       - print indented coloured error message to stderr
	printStep         - print progress information and end that line with "done"
	printTemplate     - print a template string with variables replaced by values
	printTemplateFile - print a template file with variables replaced by values
	printWarning      - print coloured warning message to stderr
	printWarning2     - print indented coloured warning message to stderr
	strRLE            - run-length encode string

Following global variables are provided:

	ERR_OK, ERR_NOERR     - normal exit status, no error
	ERR_INFO              - INFORMATIONS (no action needed)
	ERR_WARN              - WARNINGS (no immediate action)
	ERR_ARGS              - Warning, no or wrong number of arguments
	ERR_NOT_IMPLEMENTED   - Warning, feature not (yet) implemented
	ERR_UNKNOWN_ARGUMENT  - Warning, unknown or not well-formed argument
	ERR_UNKNOWN_OPTION    - Warning, unknown or not well-formed option
	ERR_OTHER_INSTANCE    - Warning, other instance of script is running
	ERR_ERROR             - ERRORS (needs immediate investigation)
	ERR_UNKNOWN_FACILITY  - Error, unknown facility
	ERR_DISALLOW_FACILITY - Error, do not run on this facility
	ERR_LIB_NOT_FOUND     - Error, could not find library
	ERR_CRASH             - CRASHES (needs immediate recovery action)



## lib_csv

	source lib_csv.bash

This library provides functions for handling a restricted set of comma
separated values (csv) files. The restriction is, that neither the field
separator nor a newline is allowed within a data field. This also applies
for data field values that are quoted.

An example csv file looks like

	ID,first name,last name,birthday,telephone,city
	28,Andreas,Tusche,20.3.1967,06201/69916,Weinheim
	42,Douglas N.,Adams,1952-03-11,,Cambridge
	4711,Willhelm,"von Lemmen",3. Oct. 1794,,Cologne

The provided functions allow to use the file name of the csv file or - if
you prefer a data base approach - to "connect" to the database table and
use a handler. As a general rule: if a database handler is used, you get
_cached_ information. File handlers are strings in the format "@@csv@@*",
where the "*" stands for an integer number.

For each function an information has to be provided if the table header (if
present) has to be taken into account for the desired operation. If the 
-h option is used, the file read or written is considered to already have a
header.

	csv_connect               [-h] DIRECTORY FILENAME
	csv_disconnect            [-h] FILEHANDLER
	csv_info                  [-h] FILENAME

	csv_readHead              [-h] FILENAME 
	csv_writeHead             [-h] FILENAME ARRAY
	csv_replaceHead           [-h] FILENAME ARRAY
	csv_removeHead            [-h] FILENAME

	csv_readLine              [-h] FILENAME 
	csv_writeLine             [-h] FILENAME ARRAY
	csv_replaceLine           [-h] FILENAME KEY_OR_LINENO ARRAY 
	csv_insertLine            [-h] FILENAME [-a|-b] KEY_OR_LINENO ARRAY
	csv_removeLine            [-h] FILENAME KEY_OR_LINENO

	csv_readKeys              [-h] FILENAME 
	csv_autoKeys              [-h] FILENAME 
	csv_createKeys            [-h] FILENAME {COLKEY_OR_COLNO}...

	csv_readColumn            [-h] FILENAME 
	csv_writeColumn           [-h] FILENAME ARRAY
	csv_replaceColumn         [-h] FILENAME {COLKEY_OR_COLNO}...ARRAY
	csv_insertColumn          [-h] FILENAME [-a|-b] COLKEY_OR_COLNO ARRAY
	csv_removeColumn          [-h] FILENAME COLKEY_OR_COLNO

	csv_sort                  [-h] FILENAME {COLKEY_OR_COLNO}...

	csv_count                 [-h] FILENAME {COLKEY_OR_COLNO}...
	csv_countIf               [-h] FILENAME {COLKEY_OR_COLNO REGEX}...
	csv_sum                   [-h] FILENAME {COLKEY_OR_COLNO}...
	csv_sumIf                 [-h] FILENAME {COLKEY_OR_COLNO REGEX}...

	csv_get                   [-h] FILENAME COLKEY_OR_COLNO KEY_OR_LINENO
	csv_set                   [-h] FILENAME COLKEY_OR_COLNO KEY_OR_LINENO VALUE

	csv_getLines              [-h] FILENAME {COLKEY_OR_COLNO REGEX}...
	csv_select                [-h] FILENAME {COLKEY_OR_COLNO REGEX}... (same as above)

	csv_walk                  [-h] FILENAME FUNCTIONNAME [ARGUMENTS...]
	csv_convert               [-h] FILENAME 
	csv_pivot                 [-h] FILENAME 



## lib_debug

	source lib_debug.bash

This library provides functions for debug purposes:

	debug_assert()             - exit if condition is false
	debug_printBashVariables() - print some bash built-in variables
	trap_err()    - error  trap handler
	trap_exit()   - exit   trap handler
	trap_debug()  - debug  trap handler
	trap_return() - return trap handler

SEE ALSO lib_common.bash for printDebug() function



## lib_time

	source lib_time.bash [--help]

This library provides functions for time calculations:

	time_add            - add a time span  to a given date
	time_addYears       - add some years   to a given date
	time_addMonths      - add some months  to a given date
	time_addDays        - add some days    to a given date
	time_addHours       - add some hours   to a given date
	time_addMinutes     - add some minutes to a given date
	time_addSeconds     - add some seconds to a given date
	time_compare        - compare two dates
	time_convert        - convert time string from one format into another
	time_diff           - difference between two dates
	time_getMonth       - get month of year from a month's name or from a time-stamp
	time_getMonthName   - get the month's name from a month of year
	time_getYear        - get year from time-stamp
	time_normalise      - clean up an array of time to represent a valid date
	time_now            - returns the array of time of the current time in UTC
	time_parse          - parse a time string into an array of time
	time_pduCycle       - convert time into PDU cycle
	time_printf         - formatted output of time
	time_serialise      - for internal calculations, serialised time
	time_setDate        - reset the year, month, and day of the given date
	time_setYear        - reset the year   of the given date
	time_setMonth       - reset the month  of the given date
	time_setDay         - reset the day    of the given date
	time_setTime        - reset the hour, minute, and second of the given date
	time_setHour        - reset the hour   of the given date
	time_setMinute      - reset the minute of the given date
	time_setSecond      - reset the second of the given date
	time_spanAdd        - add two time spans
	time_spanMultiply   - multiply time span with scalar
	time_spanNegate     - negate every element of the time array
	time_spanSerialise  - for internal calculations, serialised time span
	time_spanSubtract   - subtract two time spans
	time_spanUnserialise- for internal calculations, serialised time
	time_subtract	    - subtract a time span  from a given date
	time_subYears       - subtract some years   from a given date
	time_subMonths      - subtract some months  from a given date
	time_subDays        - subtract some days    from a given date
	time_subHours       - subtract some hours   from a given date
	time_subMinutes     - subtract some minutes from a given date
	time_subSeconds     - subtract some seconds from a given date
	time_today          - array of time of the current day 0:00:00 in UTC
	time_tomorrow       - array of time of tomorrow 0:00:00 in UTC
	time_unserialise    - for internal calculations, serialised time
	time_yesterday      - array of time of yesterday 0:00:00 in UTC

There are two types of "times" representing:

1. A valid absolute moment in the time, TIME
2. A difference between two moments in the time, TIMESPAN

The internal representation of TIMEs and TIMESPANs is an eight dimensional
ordered array like

	( year month day hours minutes seconds milliseconds microseconds )

All time calculations are expected to be done in the same time zone. For
conversion between dates, all dates are expected to be Gregorian dates and
times are in UTC (Universal Coordinated Time).

The following arithmetic operations are permitted (all others are not):

* Addition:

		TIME     + TIMESPAN = TIME      (time_add)
		TIMESPAN + TIMESPAN = TIMESPAN  (time_spanAdd)

* Subtraction:

		TIME     - TIME     = TIMESPAN  (time_diff)
		TIME     - TIMESPAN = TIME      (time_subtract)
		TIMESPAN - TIMESPAN = TIMESPAN  (time_spansubtract)
* Multiplication:

		TIMESPAN * number   = TIMESPAN  (time_spanMultiply)

* Unitary minus:

		-TIMESPAN           = TIMESPAN  (time_spanNegate)

Be careful when adding months or years because months have 28 to 31 days,
years have 365 or 366 days. The result therefore is normalised after
calculation. Example: adding 1 month to the 31. March would result in the
31. April, which does not exist. The result of that calculation will be the
1. May.

When the time span uses mixed positive and negative numbers, the result is
depended on the order of calculation. Imagine, we add 1 month to and
subtract 1 day from the date 1. Mar. 2001:

a) 1.Mar.2001 + 1 month =  1.Apr.2001 ... - 1 day   = 31.Mar.2001
b) 1.Mar.2001 - 1 day   = 28.Feb.2001 ... + 1 month = 28.Mar.2001

The functions in this library use scenario a, e.g. add years and months
first and then days, hours, etc.

SEE ALSO lib_calendar.bash



## lib_xml.bash


	source lib_xml.bash [--help]

This library provides simple functions for reading XML files.

	xml_extract              - extract values
	xml_extractMultiElements - extract multiple values from one XML file
	xml_extractMultiFiles    - extract one element from multiple XML files

