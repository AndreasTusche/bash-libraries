#
# NAME
#
#	lib_common - a bash functions library
#
# SYNOPSIS
#
#	source lib_common.bash [--help]
#
# DESCRIPTION
#
#	This library provides a collection of functions that are common to a
#	number of scripts and don't fit into one of the other libraries.
#	The functions of this library are not prefixed by the library identifier
#	'common_' but have speaking names.
#
#	enum              - enumerate a list of strings and create variables
#	rotateLog         - rotate log files and keep n copies 
#	printDebug        - print coloured debug message to stderr
#	printDebug2       - print indented coloured debug message to stderr
#	printError        - print coloured error message to stderr
#	printError2       - print indented coloured error message to stderr
#	printStep         - print progress information and end that line with "done"
#	printTemplate     - print a template string with variables replaced by values
#	printTemplateFile - print a template file with variables replaced by values
#	printWarning      - print coloured warning message to stderr
#	printWarning2     - print indented coloured warning message to stderr
#	strRLE            - run-length encode string
#
#	Following global variables are provided:
#		ERR_OK, ERR_NOERR     - normal exit status, no error
#		ERR_INFO              - INFORMATIONS (no action needed)
#		ERR_WARN              - WARNINGS (no immediate action)
#		ERR_ARGS              - Warning, no or wrong number of arguments
#		ERR_NOT_IMPLEMENTED   - Warning, feature not (yet) implemented
#		ERR_UNKNOWN_ARGUMENT  - Warning, unknown or not well-formed argument
#		ERR_UNKNOWN_OPTION    - Warning, unknown or not well-formed option
#		ERR_OTHER_INSTANCE    - Warning, other instance of script is running
#		ERR_ERROR             - ERRORS (needs immediate investigation)
#		ERR_UNKNOWN_FACILITY  - Error, unknown facility
#		ERR_DISALLOW_FACILITY - Error, do not run on this facility
#		ERR_LIB_NOT_FOUND     - Error, could not find library
#		ERR_CRASH             - CRASHES (needs immediate recovery action)
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

(( ${common_lib_loaded:-0} )) && return 0 # load me only once

###############################################################################
# config
###############################################################################

#------------------------------------------------------------------------------
# --- nothing beyond this line should need configuration ! ---

# general global constants
readonly common_MY_VERSION='$Revision: 1.0 $' # version of this library

###############################################################################
# all arguments are handled by the calling script, but in case help is needed
###############################################################################

if [[ "${0##*/}" == "lib_common.bash" && "$1" == "--help" ]] ; then
	awk '/^# NAME/,/^#===|^####/ {print l;sub(/^# ?/,"",$0);l=$0}' "${0%/*}/${0##*/}"
	exit
fi

###############################################################################
# return codes
###############################################################################

readonly ERR_OK=0             # normal exit status, no error
readonly ERR_NOERR=0          # normal exit status, no error
readonly ERR_INFO=10          # use 10-39 for INFORMATIONS (no action needed)
readonly ERR_NOTHING_TO_DO=11          # Info there is nothing to do for this script
readonly ERR_WARN=40          # use 40-69 for WARNINGS (no immediate action)
readonly ERR_ARGS=41                   # Warning, no or wrong number of arguments
readonly ERR_NOT_IMPLEMENTED=42        # Warning, feature not (yet) implemented
readonly ERR_UNKNOWN_ARGUMENT=43       # Warning, unknown or not well-formed argument
readonly ERR_UNKNOWN_OPTION=44         # Warning, unknown or not well-formed option
readonly ERR_OTHER_INSTANCE=45         # Warning, other instance of script is running
readonly ERR_ERROR=50         # use 50-59 for ERRORS (needs immediate investigation)
readonly ERR_UNKNOWN_FACILITY=51       # Error, unknown facility
readonly ERR_DISALLOW_FACILITY=52      # Error, do not run on this facility
readonly ERR_LIB_NOT_FOUND=53          # Error, could not find library
readonly ERR_FILE_NOT_FOUND=54         # Error, could not find file
readonly ERR_DIR_NOT_FOUND=55          # Error, could not find directory
readonly ERR_CRASH=60         # use 60-63 for CRASHES (needs immediate recovery action)
# 64 to 78 are reserved for system program exit status codes (see sysexits.h)
# readonly ERR_USAGE=64                # command line usage error
# readonly ERR_DATAERR=65              # data format error
# readonly ERR_NOINPUT=66              # cannot open input
# readonly ERR_NOUSER=67               # addressee unknown
# readonly ERR_NOHOST=68               # host name unknown
# readonly ERR_UNAVAILABLE=69          # service unavailable
# readonly ERR_SOFTWARE=70             # internal software error
# readonly ERR_OSERR=71                # system error (e.g., can't fork)
# readonly ERR_OSFILE=72               # critical OS file missing
# readonly ERR_CANTCREAT=73            # can't create (user) output file
# readonly ERR_IOERR=74                # input/output error
# readonly ERR_TEMPFAIL=75             # temp failure; user is invited to retry
# readonly ERR_PROTOCOL=76             # remote error in protocol
# readonly ERR_NOPERM=77               # permission denied
# readonly ERR_CONFIG=78               # configuration error

###############################################################################
# Functions
###############################################################################

#==============================================================================
# enum - enumerate a list of strings and create variables
#
# SYNOPSIS
#	enum [ -0 | -1 | -n NUMBER ] [-p PREFIX] LIST
#
# DESCRIPTION
#	This function walks through a list of strings and creates variables with
#	the same names. Each variable is assigned an integer value, starting from 0
#	or 1 or any given number and incrementing by one.
#
# OPTIONS
#	[ -0 | -1 | -n NUMBER ]
#		Define the number of the first element (0, 1, or NUMBER), 0 is the
#		default. This must be the first argument to the function.
#
#	[-p PREFIX]
#		Prefix the created variable names with PREFIX. Defaults to an
#		empty string. If used, this option must be after the -0, -1 or
#		-n option.
#
#	LIST
#		List of unique strings.
#
# DIAGNOSTICS
#	This function returns the next number following the last assigned value.
#
# EXAMPLE
#	enum ONE TWO THREE
#		This creates three variables, where $ONE is 0, $TWO is 1, and $THREE
#		is 2. The return value is 3.
#
#	enum -1 ONE TWO THREE
#		This creates three variables, where $ONE is 1, $TWO is 2, and $THREE
#		is 3. The return value is 4.
#
#	enum -n 42 ONE TWO THREE
#		This creates three variables, where $ONE is 42, $TWO is 43, and
#		$THREE is 44. The return value is 45.
#
#	enum -p var 0 8 15 42
#		This creates four variables, where $var0 is 0, $var8 is 1,
#		$var15 is 2, and $var42 is 3. The return value is 4.
#
#	enum -n 4711 -p my_ ONE TWO THREE
#		This creates three variables, where $my_ONE is 4711, $my_TWO is 4712,
#		and $my_THREE is 4713. The return value is 4714.
#
# GLOBAL VARIABLES SET
#	return                             # integer or string holding the result
#	and all elements of the LIST are turned into global variables as well
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.090204===

function enum { # [-0 | -1 | -n NUMBER] [-p PREFIX] ( LIST_OF_VARNAMES )
	local -i i
	local first=0 prefix=""

	case $1 in
		-0) first=0  ; shift ;;
		-1) first=1  ; shift ;;
		-n) first=$2 ; shift 2 ;;
	esac
	case $1 in
		-p) prefix=$2 ; shift 2 ;;
	esac

	for (( i=1; $i<=$#; i++ )) ; do
		eval ${prefix}${!i}=$(( $i + $first - 1 ))
		(($DEBUG)) && printDebug "${FUNCNAME}: ${prefix}${!i} = $(( $i + $first - 1 ))"
	done

	return=$(( $i + $first - 1 ))
	return $return
}

#==============================================================================
# rotateLog - rotate log files and keep only some copies
#
# SYNOPSIS
#	rotateLog FILE [NUMBER]
#
# DESCRIPTION
#	This function keeps NUMBER previous copies of the given FILE. The
#	youngest file will get the extension ".01", the file prior to that
#	gets the extension ".02" and so on.
#	
#	Don't confuse it with the time-based UNIX "rotatelogs" command.
#
# OPTIONS
#	FILE
#		The full path and file name of the log file to be rotated
#
#	[NUMBER]
#		Optionally define the number of the files to keep, the maximum
#		should not exceed 99. The default is 9.
#
# EXAMPLE
#	rotateLog /data/logs/my.log 3
#		This will keep /data/logs/my.log and /data/logs/my.log.{02,01}.
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.131021===

function rotateLog { # FILE [NUMBER]
	local f="${1}" n=${2:-9}
	local fNew fOld fOlder fOldest="$(printf "%s.%02d" "${f}" ${n})"

	if [ "$f" == "" ]; then
		return
	fi

	for (( i=(n-1); i>1; i-- )); do
		(( h = i - 1 , j = i + 1 ))
		fNew=$(printf "%s.%02d" "${f}" ${h})
		fOld=$(printf "%s.%02d" "${f}" ${i})
		fOlder=$(printf "%s.%02d" "${f}" ${j})
		
		if [ -f "${fNew}" -a -f "${fOld}" ] ; then
                    mv "${fOld}" "${fOlder}"
		fi
	done

	if [ -f "$f" ] ; then
		if [ -f "$f.01" ] ; then
			mv "${f}.01" "${f}.02"
		fi

		mv "${f}" "${f}.01"
	fi

	if [ -f "$fOldest" ] ; then
		find "${f%/*}" ! -newer "$fOldest" -name "${f##*/}*" -exec rm {} \;
	fi
}

#==============================================================================
# printDebug    - output a coloured string to stderr
# printDebug2   - output further coloured lines to stderr
# printError    - output a coloured string to stderr
# printError2   - output further coloured lines to stderr
# printWarning  - output a coloured string to stderr
# printWarning2 - output further coloured lines to stderr
#
# SYNOPSIS
#	printDebug STRING
#	printDebug2 STRING
#	printErr STRING
#	printErr2 STRING
#	printWarning STRING
#	printWarning2 STRING
#
# DESCRIPTION
#	These functions print debug, error or a warning messages in magenta,
#	red or black on yellow respective to stderr. Further indented lines can be 
#	printed using the print*2() functions.
#
# OPTIONS
#	STRING  The string to be printed, prefixed by the word DEBUG, ERROR
#		or WARNING.
#
# EXAMPLE
#	printDebug   "HAL 9000 initialising."
#	printError   "Sorry Dave, I can't do that."
#	printWarning "The main antenna will fail in 42 hours."
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.131022===

function printDebug {
	(($_printStep_len)) && echo ""
	echo -e "\e[01;35mDEBUG:\e[00;35m ${@}\e[0m" >&2
}

function printDebug2 {
	(($_printStep_len)) && echo ""
	echo -e "      \e[00;35m ${@}\e[0m" >&2
}

function printError {
	(($_printStep_len)) && echo ""
	echo -e "\e[01;31mERROR:\e[00;31m ${@}\e[0m" >&2
}

function printError2 {
	(($_printStep_len)) && echo ""
	echo -e "      \e[00;31m ${@}\e[0m" >&2
}

function printWarning {
	(($_printStep_len)) && echo ""
	echo -e "\e[01;30;43mWARNING:\e[00;30;43m ${@}\e[0m" >&2
}

function printWarning2 {
	(($_printStep_len)) && echo ""
	echo -e "      \e[00;30;43m ${@}\e[0m" >&2
}

#==============================================================================
# printStep - print one line of information or end that line with "done"
#
# SYNOPSIS
#	printStep BOOLDSTRING MESSAGESTRING
#	printStep [-n] {-d | done}
#
# DESCRIPTION
#	This function prints the first BOLDSTRING in bold and the MESSAGESTRING
#	in normal font. The output will NOT be terminated by a line feed.
#	The total length of the message is stored.
#	In case the BOLDSTRING equals "done", then the word "done" is printed in 
#	green colour at the end of the line and terminated by a line feed.
#	If you want the word "done" to appear on a separate line then use the -n
#	option.
#
# OPTIONS
#	BOLDSTRING     The string to be printed in bold.
#	MESSAGESTRING  The message to be printed in normal font
#	done           The literal "done", makes the function to end the line.
#	-d             The literal "done", makes the function to end the line.
#	-n             Make the "done" appear on a separate line.
#
# EXAMPLE
#	printStep INFO Read the fantastic manual.
#	printStep done
#		This will result in the output
#		INFO: Read the fantastic manual                                ... done
#	where the word "INFO" is printed in bold.
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.131022===

function printStep {
	case "${1}" in
		-n)
			_printStep_len=0
			shift
			;;
	esac

	local bold="${1}" ; shift
	local lenspc msg="${@}"

	case "$bold" in
		-d|[Dd][Oo][Nn][Ee])
			msg="                                                                                "
			lenspc=$(( 70 - ${_printStep_len:-0} ))

			if (( $lenspc > 0 )) ; then
				echo -n "${msg:0:$lenspc}"
			else
				echo -en "\n${msg:0:70}"
			fi

			echo -e  "\e[01;32m ...\e[00;32m done\e[0m"
			_printStep_len=0
			;;
		*)
			(($_printStep_len)) && echo ""
			_printStep_len=$(( ${#bold} + ${#msg} + 2 )) 
			echo -en "\e[01m${bold}\e[0m: ${@}"
			;;
		esac
}

#==============================================================================
# printTemplate -  print a template string with variables replaced by values
#
# SYNOPSIS
#	printTemplate VARNAME
#
# DESCRIPTION
#	This function takes the string from $VARNAME and replaces all variables
#	within that string by their values. Unset variables are replaced by an
#	empty string.
#
#	Use this function for printing from templates.
#
# OPTIONS
#	VARNAME  A name of a variable that holds the template string.
#
# EXAMPLE
#	template='I am ${USER}. My favourite number is ${a[2]}.'
#	a=( 40 41 42 43 44 )
#	printTemplate template
#		This will print:
#		I am antu. My favourite number is 42.'
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.090130===

function printTemplate { # TEMPLATE
	eval echo -e '"'"$( echo "${!1}" | sed 's/"/\\"/g' )"'"'
}

#==============================================================================
# printTemplateFile - print a template file with variables replaced by values
#
# SYNOPSIS
#	printTemplateFile FILENAME
#
# DESCRIPTION
#	This function takes the content from the file FILENAME and replaces all
#	variables by their values. Unset variables are replaced by an empty string.
#
#	Use this function for printing from templates.
#
# OPTIONS
#	FILENAME  A file name of a template file.
#
# EXAMPLE
#	echo 'I am ${USER}. My favourite number is ${a[2]}.' > template.txt
#	a=( 40 41 42 43 44 )
#	printTemplateFile template.txt
#		This will print:
#		I am antu. My favourite number is 42.'
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.090130===

function printTemplateFile { # FILENAME
	eval echo -e '"'"$(sed 's/"/\\"/g' "$@")"'"'
}


#==============================================================================
# strRLE - run-length encode string
#
# SYNOPSIS
#	strRLE [-d DELIM] [-d DELIM2] STRING
#
# DESCRIPTION
#	For each char in the STRING, the number of succeeding occurrences are
#	counted. The char and the count are printed. separated by DELIM. Pairs
#	of chars and counts are separated by DELIM2.
#	Each space or tab in the input string is converted into "_" (underscore).
#
# OPTIONS
#	-d DELIM   First delimiter, defaults to " " (SPACE)
#	-d DELIM2  Second delimiter, defaults to " " (SPACE)
#	STRING     The string to encode. Use printable chars only.
#
# DIAGNOSTICS
#	This function returns the next number of char blocks.
#
# EXAMPLE
#	strRLE "strRLE "44444441"
#		This will print: 4 7 1 1 . The return value is 2.
#
#	strRLE -d , "Hello"
#		This will print: H,1,e,1,l,2,o,1,. The return value is 4.
#
#	strRLE -d "=" -d "&" "Hello mate"
#		This will print: H=1&e=1&l=2&o=1&_=1&m=1&a=1&t=1&e=1&. The
#		return value is 9.
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.090204===

function strRLE { # [-d DELIM] [-d DELIM2] STRING
	local c d1=' ' d2=' '
	local -a aC aN
	local -i i l n=0

	case $1 in -d) d1=$2 ; d2=$2 ; shift 2 ;; esac
	case $1 in -d)         d2=$2 ; shift 2 ;; esac

	l=${#1}
	for ((i=0; i<l; i++)) ; do
		c=${1:$i:1}
		[[ $c != ${aC[$n]} ]] && (( n++ ))
		aC[$n]="$c"
		aN[$n]=$((aN[$n] + 1 ))
	done

	for (( i=1; i<=n ; i++ )) ; do
		echo -n "${aC[$i]/[	 ]/_}${d1}${aN[$i]}${d2}"
	done

	return $(( i-1 ))
}

###############################################################################
# Cleanup and return
###############################################################################

declare -fr enum
declare -fr rotateLog 
declare -fr printDebug
declare -fr printDebug2
declare -fr printError
declare -fr printError2
declare -fr printStep
declare -fr printTemplate
declare -fr printTemplateFile
declare -fr printWarning
declare -fr printWarning2
declare -fr strRLE

readonly common_lib_loaded=1
return $ERR_NOERR

###############################################################################
# END
###############################################################################
