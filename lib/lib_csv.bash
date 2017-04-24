#
# NAME
#
#	lib_csv - a bash functions library
#
# SYNOPSIS
#
#	source lib_csv.bash
#
# DESCRIPTION
#
#	This library provides functions for handling a restricted set of comma
#	separated values (csv) files. The restriction is, that neither the field
#	separator nor a newline is allowed within a data field. This also applies
#	for data field values that are quoted.
#	
#	An example csv file looks like
#		ID,first name,last name,birthday,telephone,city
#		28,Andreas,Tusche,20.3.1967,06201/69916,Weinheim
#		42,Douglas N.,Adams,1952-03-11,,Cambridge
#		4711,Willhelm,"von Lemmen",3. Oct. 1794,,Cologne
#
#	The provided functions allow to use the file name of the csv file or - if
#	you prefer a data base approach - to "connect" to the database table and
#	use a handler. As a general rule: if a database handler is used, you get
#	_cached_ information. File handlers are strings in the format "@@csv@@*",
#	where the "*" stands for an integer number.
#
#	For each function an information has to be provided if the table header (if
#	present) has to be taken into account for the desired operation. If the 
#	-h option is used, the file read or written is considered to already have a
#	header.
#
#	csv_connect               [-h] DIRECTORY FILENAME
#	csv_disconnect            [-h] FILEHANDLER
#	csv_info                  [-h] FILENAME
#
#	csv_readHead              [-h] FILENAME 
#	csv_writeHead             [-h] FILENAME ARRAY
#	csv_replaceHead           [-h] FILENAME ARRAY
#	csv_removeHead            [-h] FILENAME
# 
#	csv_readLine              [-h] FILENAME 
#	csv_writeLine             [-h] FILENAME ARRAY
#	csv_replaceLine           [-h] FILENAME KEY_OR_LINENO ARRAY 
#	csv_insertLine            [-h] FILENAME [-a|-b] KEY_OR_LINENO ARRAY
#	csv_removeLine            [-h] FILENAME KEY_OR_LINENO
# 
#	csv_readKeys              [-h] FILENAME 
#	csv_autoKeys              [-h] FILENAME 
#	csv_createKeys            [-h] FILENAME {COLKEY_OR_COLNO}...
# 
#	csv_readColumn            [-h] FILENAME 
#	csv_writeColumn           [-h] FILENAME ARRAY
#	csv_replaceColumn         [-h] FILENAME {COLKEY_OR_COLNO}...ARRAY
#	csv_insertColumn          [-h] FILENAME [-a|-b] COLKEY_OR_COLNO ARRAY
#	csv_removeColumn          [-h] FILENAME COLKEY_OR_COLNO
# 
#	csv_sort                  [-h] FILENAME {COLKEY_OR_COLNO}...
# 
#	csv_count                 [-h] FILENAME {COLKEY_OR_COLNO}...
#	csv_countIf               [-h] FILENAME {COLKEY_OR_COLNO REGEX}...
#	csv_sum                   [-h] FILENAME {COLKEY_OR_COLNO}...
#	csv_sumIf                 [-h] FILENAME {COLKEY_OR_COLNO REGEX}...
# 
#	csv_get                   [-h] FILENAME COLKEY_OR_COLNO KEY_OR_LINENO
#	csv_set                   [-h] FILENAME COLKEY_OR_COLNO KEY_OR_LINENO VALUE
# 
#	csv_getLines              [-h] FILENAME {COLKEY_OR_COLNO REGEX}...
#	csv_select                [-h] FILENAME {COLKEY_OR_COLNO REGEX}... (same as above)
#
#	csv_walk                  [-h] FILENAME FUNCTIONNAME [ARGUMENTS...]
#	csv_convert               [-h] FILENAME 
#	csv_pivot                 [-h] FILENAME 
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

(( ${csv_lib_loaded:-0} )) && return 0 # load me only once

###############################################################################
# config
###############################################################################

# misc
csv_FS="," # field seperator

# --- nothing beyond this line should need configuration ! ---

# general global variables
csv_DEBUG=${DEBUG:-0}             # no debugging by default
csv_VERBOSE=${VERBOSE:-0}         # verbose defaults to FALSE

# general global constants
readonly csv_MY_VERSION='$Revision: 1.0 $' # version of this library
readonly csv_oldIFS="$IFS"        # store standard Internal Field Separator

# use error codes between 3 and 125 (the others are reserved by bash)
readonly csv_ERR_NOERR=${ERR_NOERR:-0}      # normal exit status, no error
readonly csv_ERR_INFO=${ERR_INFO:-10}       # use 10-39 for INFORMATIONS (no action needed)
readonly csv_ERR_WARN=${ERR_WARN:-40}       # use 40-69 for WARNINGS (no immediate action)
readonly csv_ERR_ARGS=${ERR_ARGS:-41}                           # Warning, no or wrong number of arguments
readonly csv_ERR_NOT_IMPLEMENTED=${ERR_NOT_IMPLEMENTED:-42}     # Warning, feature not (yet) implemented
readonly csv_ERR_UNKNOWN_ARGUMENT=${ERR_UNKNOWN_ARGUMENT:-43}   # Warning, unknown or not well-formed argument
readonly csv_ERR_UNKNOWN_OPTION=${ERR_UNKNOWN_OPTION:-44}       # Warning, unknown or not well-formed option
readonly csv_ERR_ERROR=${ERR_ERROR:-70}     # use 70-99 for ERRORS (needs immediate investigation)
readonly csv_ERR_UNKNOWN_FACILITY=${ERR_UNKNOWN_FACILITY:-71}   # Error, unknown facility
readonly csv_ERR_FILE_NOT_FOUND=${ERR_FILE_NOT_FOUND:-72}       # Error, unknown facility
readonly csv_ERR_CRASH=${ERR_CRASH:-100}    # use 100-  for CRASHES (needs immediate recovery action)


### File handler => instead of file name give handler like "@@csv@@NN", NN=number
### have array to store info per NN:
declare -a _csv_cache_HEADER  # string with space-separated column-keys or "0"
declare -a _csv_cache_KEYS    # string with space-separated line-keys
declare -a _csv_cache_TABLE   # string with path (directory name and file name)
declare -a _csv_cache_ZIPPED  # flag if file was compressed with gzip

###############################################################################
# all arguments are handled by the calling script, but in case help is needed
###############################################################################

if [[ "${0##*/}" == "lib_csv.bash" && "$1" == "--help" ]] ; then 
	awk '/^# NAME/,/^#===|^####/ {print l;sub(/^# ?/,"",$0);l=$0}' "${0%/*}/${0##*/}"
	exit
fi

###############################################################################
# Functions
###############################################################################

#==============================================================================
# csv_connect                 [-h] PATH
#==============================================================================

function csv_connect { #      [-h] PATH
	local skipHead=1 ; if [[ "$1" == "-h" ]] ; then skipHead=0 ; shift ; fi
	local filename="$1"

	local awkScript
	local n=$(( ${#_csv_cache_TABLE[*]} + 1 )) # next index
	local wasZipped=0
	
	# bail out if file and file.gz not found
	if [ ! -e "${filename}" ] ; then
		if [ -e "${filename}.gz" ] ; then 
			wasZipped=1
			gunzip "${filename}.gz"
		else
			return=0
			return $csv_ERR_FILE_NOT_FOUND
		fi
	fi
	
	# if this file already was connected, use same handler
	for (( i=0; i<n; i++ )) ; do
		if [[ "${_csv_cache_TABLE[$i]}" == "$filename" ]] ; then
			n=$i
			break
		fi
	done

	_csv_cache_TABLE[$n]="$filename"

	if (( $skipHead )) ; then
		_csv_cache_HEADER[$n]=0
		_csv_cache_KEYS[$n]="$(   csv_readKeys    $filename )"
	else
		_csv_cache_HEADER[$n]="$( csv_readHead    $filename )"
		_csv_cache_KEYS[$n]="$(   csv_readKeys -h $filename )"
	fi
	
	_csv_cache_ZIPPED[$n]=$wasZipped

	return="@@csv@@${n}"
	echo "$return"
}


#==============================================================================
# csv_disconnect              [-h] FILENAME
#==============================================================================

function csv_disconnect { #   [-h] FILENAME
	if [[ "$1" == "-h" ]] ; then shift; fi   # don't need it here
	local filename="$1"
	local n=0
	
	case "$filename" in
		"@@csv@@"*)           # have file handler - get cached info
			n=${filename:7}
			;;
		*)			          # check if this file already was connected
			for (( i=0; i<n; i++ )) ; do
				if [[ "${_csv_cache_TABLE[$i]}" == "$filename" ]] ; then
					n=$i
					break
				fi
			done
			;;
	esac

	# compress file if it was compressed at csv_connect()
	if (( _csv_cache_ZIPPED[$n] == 1 )) ; then
		gzip "${_csv_cache_TABLE[$n]}"
	fi

	# deregister table info from cache
	_csv_cache_TABLE[$n]=0
	_csv_cache_HEADER[$n]=0
	_csv_cache_KEYS[$n]=0
	_csv_cache_ZIPPED[$n]=0
}


#==============================================================================
# csv_info                [-h] FILENAME
#==============================================================================

function csv_info { #         [-h] FILENAME
	IFS=$csv_FS read -a return < "${1}"
	echo ${return[*]} 
}


#==============================================================================
# csv_readHead            [-h] FILENAME 
#==============================================================================

function csv_readHead { # [-h] FILENAME
	if [[ "$1" == "-h" ]] ; then shift; fi   # don't need it here
	local filename="$1"
	local awkScript
	
	case "$filename" in
		"@@csv@@"*)           # have file handler - get cached info
			n=${filename:7}
			return=( ${_csv_cache_HEADER[$n]} )
			;;
		*)                    # reads first line regardless of -h option
			awkScript='
				BEGIN {FS="[\"]?'${csv_FS}'[\"]?"}
				NR>1 {exit}
				{ for (i=1; i<=NF; i++) printf $i" " }
				'
			return=( $( awk "$awkScript" < "$filename" ) )
			;;
	esac

	echo ${return[*]} 
}



#==============================================================================
# csv_readKeys            [-h] FILENAME 
#==============================================================================

function csv_readKeys { # [-h] FILENAME
	local skipHead=1 ; if [[ "$1" == "-h" ]] ; then skipHead=0 ; shift ; fi
	local filename="$1"
	local awkScript
	
	case "$filename" in
		"@@csv@@"*)           # have file handler - get cached info
			n=${filename:7}
			return=( _csv_cache_KEYS[$n] )
			;;
		*)
			awkScript='
				BEGIN {FS="[\"]?'${csv_FS}'[\"]?"}
				NR>'${skipHead}' { printf $1" " }
				'
			return=( $( awk "$awkScript" < "$filename" ) )
			;;
	esac

	echo ${return[*]} 
}


#==============================================================================
# csv_walk - apply a command to all lines of a csv file
#
# SYNOPSIS
#	csv_walk [-h] FILENAME FUNCTIONNAME [ARGUMENTS...]
#
# DESCRIPTION
#	This function applies a command to all lines of a csv file. The csv file is
#	read line be line, the values in that line are extracted. The named
#   FUNCTION then is called with all given ARGUMENTS and all values of that
#	line.
#
# OPTIONS
#	-h 
#		If not set, the the header of the csv file will be omitted.
#
#	FILENAME
#		The file name of the csv file.
#
#	FUNCTIONNAME
#		The name of the function that needs to be called for each line.
#
#   ARGUMENTS
#		Some arguments that are passed to the function.
#
# EXAMPLE
#	Imagine we had a csv file mini.csv like this:
#		Name,City,Telephone
#		Andy,Cologne,75842
#		Manni,Wiehl,69916
#
#	The function call
#		csv_walk mini.csv printf "%2.2s%2.2s"
#	would execute as (note the header and the commas have gone)
#		printf "%2.2s%2.2s%2.2s" Andy Cologne 75842
#		printf "%2.2s%2.2s%2.2s" Manni Wiehl 69916
#	The following output would go to stdout:
#		AnCo75
#		MaWi69
#
# AUTHOR
#     Written by Andreas Tusche (bash-libraries@andreas-tusche.de)
#===================================================================V.080425===

function csv_walk { # [-h] FILENAME FUNCTIONNAME [ARGUMENTS...]
	local skipHead=1 ; if [[ "$1" == "-h" ]] ; then skipHead=0 ; shift ; fi
	local filename="$1"
	local functionname=$2
	shift 2

	local -a line

	{ # group_of_commands
		if (( $skipHead )) ; then read ; fi # skip header

		while IFS=$csv_FS read -a line ; do
			$functionname "$@" ${line[*]}
		done

	} < "$filename" # input file to group_of_commands
}


###############################################################################
# Clean-up and return
###############################################################################

declare -fr csv_connect
declare -fr csv_disconnect
declare -fr csv_info
declare -fr csv_readHead
declare -fr csv_readKeys
declare -fr csv_walk

readonly csv_lib_loaded=1
return $csv_ERR_NOERR

###############################################################################
# END
###############################################################################
# @ToDo csv_writeHead
# @ToDo csv_replaceHead
# @ToDo csv_removeHead
# @ToDo csv_readLine
# @ToDo csv_writeLine
# @ToDo csv_replaceLine
# @ToDo csv_insertLine
# @ToDo csv_removeLine
# @ToDo csv_autoKeys
# @ToDo csv_createKeys
# @ToDo csv_readColumn
# @ToDo csv_writeColumn
# @ToDo csv_replaceColumn
# @ToDo csv_insertColumn
# @ToDo csv_removeColumn
# @ToDo csv_sort
# @ToDo csv_count
# @ToDo csv_countIf
# @ToDo csv_sum
# @ToDo csv_sumIf
# @ToDo csv_get
# @ToDo csv_set
# @ToDo csv_getLines
# @ToDo csv_select
# @ToDo csv_convert
# @ToDo csv_pivot
