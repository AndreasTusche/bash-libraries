#
# NAME
#
#	lib_array - bash library, provide some array related functions
#
# SYNOPSIS
#
#	source lib_array.bash
#
# DESCRIPTION
#
#	This library provides functions for array handling:
#		array_reverse() - reverses an array
#		array_shift()   - shifts array elements
#		array_sort()    - sorts array elements
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

(( ${array_lib_loaded:-0} )) && return 0 # load me only once

###############################################################################
# config
###############################################################################

# general global variables
array_DEBUG=${DEBUG:-0}             # no debugging by default
array_VERBOSE=${VERBOSE:-0}         # verbose defaults to FALSE

# general global constants
readonly array_MY_VERSION='$Revision: 1.0 $' # version of this library

# error codes
readonly array_ERR_NOERR=${ERR_NOERR:-0}      # normal exit status, no error

###############################################################################
# all arguments are handled by the calling script, but in case help is needed
###############################################################################

if [[ "${0##*/}" == "lib_array.bash" && "$1" == "--help" ]] ; then 
	awk '/^# NAME/,/^#===|^####/ {print l;sub(/^# ?/,"",$0);l=$0}' "${0%/*}/${0##*/}"
	exit
fi

###############################################################################
# Functions
###############################################################################

#==============================================================================
# array_reverse - reverse an array
#
# SYNOPSIS
#	array_reverse { STRING | VALUES }
#
# DESCRIPTION
#	This reverses the order of the elements of a string or an array.
#
# OPTIONS
#	STRING        a string with word separated by white-space
#	VALUES        values from an array, e.g. ${ARRAY[@]}
#
# DIAGNOSTICS
#	This function returns the reversed VALUES.
#
# EXAMPLE
#	a="one two three"
#	array_reverse $a            ---> three two one
#
#	b=( 3 1 4 1 5 9 2 6 5 3 2 )
#	array_reverse ${b[@]}       ---> 2 3 5 6 2 9 5 1 4 1 3
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.090605===

function array_reverse {
	local c
	return=""
	
	for c in $* ; do
		return="$c $return"
	done
	echo $return
}


#==============================================================================
# array_shift - like shift but for arrays
#
# SYNOPSIS
#	array_shift [-n COUNT] { STRING | VALUES }
#
# DESCRIPTION
#	Remove the first COUNT elements from a string or an array.
#
# OPTIONS
#	COUNT         number of elements to be removed, defaults to 1
#	STRING        a string with word separated by white-space
#	VALUES        values from an array, e.g. ${ARRAY[@]}
#
# DIAGNOSTICS
#	This function returns the sorted VALUES.
#
# EXAMPLE
#	a="3 1 4 1 5 9 2 6 5 3 2"
#	array_shift -n 2 $a         ---> 4 1 5 9 2 6 5 3 2
#
#	b=( 3 1 4 1 5 9 2 6 5 3 2 )
#	array_shift -n 3 ${b[@]}    ---> 1 5 9 2 6 5 3 2
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.090604===

function array_shift {
	local n=2

	case "$1" in -n) n=$(( $2 + 1 )) ; shift 2 ;; esac

	return=( ${@:$n} )
	echo "${return[@]}"	
}


#==============================================================================
# array_sort - Sort the elements of an array
#
# SYNOPSIS
#	array_sort [-u] { STRING | VALUES }
#
# DESCRIPTION
#	Sort the words of a string or the elements of an array 
#	If -u is the first arg, remove duplicate array elements.
#
# OPTIONS
#	-u, --unique  remove duplicate array elements
#	STRING        a string with word separated by white-space
#	VALUES        values from an array, e.g. ${ARRAY[@]}
#
# DIAGNOSTICS
#	This function returns the sorted VALUES.
#
# EXAMPLE
#	a="3 1 4 1 5 9 2 6 5 3 2"
#	array_sort $a               ---> 1 1 2 2 3 3 4 5 5 6 9
#
#	b=( 3 1 4 1 5 9 2 6 5 3 2 )
#	array_sort -u ${b[@]}       ---> 1 2 3 4 5 6 9
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.090604===

function array_sort {
	local u

	case "$1" in -u | --unique) u=-u ; shift ;; esac

	return=( $( printf "%s\n" "${@}" | sort $u ) )
	echo "${return[@]}"
}


###############################################################################
# Clean-up and return
###############################################################################

declare -Fr array_reverse
declare -Fr array_shift
declare -Fr array_sort

readonly array_lib_loaded=1
return $array_ERR_NOERR

###############################################################################
# END
###############################################################################
