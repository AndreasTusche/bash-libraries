#
# NAME
#
#      lib_debug - a bash functions library
#
# SYNOPSIS
#
#      source lib_debug.bash
#
# DESCRIPTION
#
#	This library provides functions for debug purposes:
#		debug_assert()             - exit if condition is false
#		debug_printBashVariables() - print some bash built-in variables
#		trap_err()    - error  trap handler
#		trap_exit()   - exit   trap handler
#		trap_debug()  - debug  trap handler
#		trap_return() - return trap handler
#
# SEE ALSO
#	lib_common.bash for printDebug() function
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

(( ${debug_lib_loaded:-0} )) && return 0 # load me only once

###############################################################################
# config
###############################################################################

# general global variables
debug_DEBUG=${DEBUG:-0}             # no debugging by default
debug_VERBOSE=${VERBOSE:-0}         # verbose defaults to FALSE

# general global constants
readonly debug_MY_VERSION='$Revision: 1.0 $' # version of this library

# use error codes between 3 and 125 (the others are reserved by bash)
readonly debug_ERR_NOERR=${ERR_NOERR:-0}      # normal exit status, no error
readonly debug_ERR_ARGS=${ERR_ARGS:-41}       # Warning, no or wrong number of arguments
readonly debug_ERR_ASSERT_FAILED=45           # Warning, assert() function failed

###############################################################################
# all arguments are handled by the calling script, but in case help is needed
###############################################################################

if [[ "${0##*/}" == "lib_debug.bash" && "$1" == "--help" ]] ; then 
	awk '/^# NAME/,/^#===|^####/ {print l;sub(/^# ?/,"",$0);l=$0}' "${0%/*}/${0##*/}"
	exit
fi

###############################################################################
# Functions
###############################################################################

#==============================================================================
# debug_assert - if condition is false then exit with error message
#
# SYNOPSIS
#	debug_assert CONDITION LINE
#
# DESCRIPTION
#	CONDITION
#		condition to be checked
#	LINE
#		line-number
#
# EXAMPLE
#	condition="$a -lt $b"
#	debug_assert "$condition" $LINENO 
#===================================================================V.080128===

function debug_assert {
	if (( $# != 2 )) ; then
		return $debug_ERR_ARGS
	fi
	
	local linenumber=$2
	
	if [ ! $1 ] ; then
		echo "Assertion failed: $1"
		echo "File $0, line $linenumber"
		exit $debug_ERR_ASSERT_FAILED
	# else
	#	return and continue executing the script
	fi 
}

#==============================================================================
# debug_printBashVariables() - print some bash built-in variables
#
# SYNOPSIS
#	debug_printBashVariables
#
# DESCRIPTION
#	This function prints some bash built-in variables
#
# DIAGNOSTICS
#	Nothing is returned
#
# EXAMPLE
#	debug_printBashVariables
#
# GLOBAL VARIABLES USED
#	some built-in bash variables (see code)
#===================================================================V.080118===

function debug_printBashVariables {
	echo '------------------------------------------------------------'
	echo 'bash options:'
	echo '............................................................'
	shopt
	echo '------------------------------------------------------------'
	echo 'bash set options:'
	echo '............................................................'
	set -o
	echo '------------------------------------------------------------'
	echo 'bash variables:'
	echo '............................................................'
	set
	echo '------------------------------------------------------------'
}

#==============================================================================
# trap_err()    - error  trap handler
# trap_exit()   - exit   trap handler
# trap_debug()  - debug  trap handler
# trap_return() - return trap handler
#
# SYNOPSIS
#	trap_err $FUNCNAME
#	trap_exit $FUNCNAME
#	trap_debug $FUNCNAME
#	trap_return $FUNCNAME
#
# DESCRIPTION
#	These functions are called by bash-internal traps.
#
# DIAGNOSTICS
#	These functions don't return anything
#
# EXAMPLE
#	trap 'trap_err' ERR
#	trap 'trap_exit' EXIT
#	trap 'trap_debug' DEBUG
#	trap 'trap_return' RETURN
#
# BUGS
#	Not thoroughly tested
#
# AUTHOR
#     Written by Andreas Tusche (bash-libraries@andreas-tusche.de)
#===================================================================V.130920===

function trap_err () { # errStatus LINENO lineCallFunc cmd stack
	local err=$1
	local line=$2
	local linecallfunc=$3 
	local command="$4"
	local funcstack="$5"
	echo -e "\e[01;31mERROR:\e[00;31m line $line - command '$command' exited with status: $err\e[0m" >&2
	if [ "$funcstack" != "::" ]; then
		echo -n "   ... Error at ${funcstack} " >&2
		if [[ "$linecallfunc" != "" && "$linecallfunc" != "0" ]] ; then
			echo -n "called at line $linecallfunc" >&2
		fi
	else
		echo -n "   ... debug info from function ${FUNCNAME} (line $linecallfunc)" >&2
	fi
	echo >&2
	echo "---" >&2
}
	
function trap_exit { # errStatus LINENO
    local err=$1
    local line=$2
	echo "EXIT line $line: Exiting with status $err." >&2
}

function trap_debug { # errStatus LINENO
    local err=$1
    local line=$2
	echo -n "${0##*/}:${line} ${2:-main}" >&2
	if [[ "$2" != "$_debug_lastFUNCNAME" ]] ; then
		_debug_lastFUNCNAME="$2"
		shift
		echo "( $@ ) {${#@}}" >&2
	else
		echo " - $err " >&2
	fi
}

function trap_return { # errStatus LINENO
    local err=$1
    local line=$2
	echo -n "${0##*/}:${line} ${2:-main} " >&2
	shift
	echo "--> ${return[@]}" >&2
}

###############################################################################
# M A I N
###############################################################################

(( $debug_DEBUG && $debug_VERBOSE )) && set -o verbose

PS4="$0 line $LINENO: "
set -o errtrace
trap 'trap_err $? $LINENO $BASH_LINENO "$BASH_COMMAND" $(printf "::%s" ${FUNCNAME[@]})' ERR

#if [[ $DEBUG && $VERBOSE ]] ; then
#	trap 'trap_exit $? $LINENO $BASH_LINENO' EXIT
#	trap 'trap_debug $? $LINENO $BASH_LINENO' DEBUG
#	trap 'trap_return $? $LINENO $BASH_LINENO' RETURN
#fi

###############################################################################
# Cleanup and return
###############################################################################

declare -Fr debug_assert
declare -Fr debug_printBashVariables
declare -F  trap_err
declare -F  trap_exit
declare -F  trap_debug
declare -F  trap_return

readonly debug_lib_loaded=1
return $debug_ERR_NOERR
exit 

###############################################################################
# END
###############################################################################
