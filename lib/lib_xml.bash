#
# NAME
#
#	lib_xml.bash      - handle the reading of XML files
#
# SYNOPSIS
#
#	source lib_xml.bash [--help]
#
# DESCRIPTION
#
#	This library provides simple functions for reading XML files.
#		xml_extract              - extract values
#		xml_extractMultiElements - extract multiple values from one XML file
#		xml_extractMultiFiles    - extract one element from multiple XML files
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

(( ${xml_lib_loaded:-0} )) && return 0 # load me only once

###############################################################################
# config
###############################################################################

#------------------------------------------------------------------------------
# --- nothing beyond this line should need configuration ! ---

# general global variables
xml_DEBUG=${DEBUG:-0}             # no debugging by default
xml_VERBOSE=${VERBOSE:-0}         # verbose defaults to FALSE

# general global constants
readonly xml_MY_VERSION='$Revision: 1.0 $' # version of this library

###############################################################################
# all arguments are handled by the calling script, but in case help is needed
###############################################################################

if [[ "${0##*/}" == "lib_xml.bash" && "$1" == "--help" ]] ; then 
	awk '/^# NAME/,/^#===|^####/ {print l;sub(/^# ?/,"",$0);l=$0}' "${0%/*}/${0##*/}"
	exit
fi

###############################################################################
# Functions
###############################################################################

#==============================================================================
# xml_extract - extraction of one element from one XML file
#
# SYNOPSIS
#	xml_extract TAGLIST FILE
#
# DESCRIPTION
#	This function extracts one element from one XML file.
#
# OPTIONS
#	TAGLIST   A colon-separated list of nested tags defining the element
#	FILE      A file name
#
# EXAMPLE
#	The XML file may contain lines like
#	<My_Report>
#		<report_header>
#			<cmd_id>4711</cmd_id>
#			<cmd_name>design_a_perfume</cmd_name>
#		</report_header>
#		[...]
#	</My_Report>
#
#	xml_extract "report_header:cmd_id" report.xml 
#		This will extract the value 4711 which is found within the cmd_id tags,
#		which itself is found between the report_header tags.
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.081114===

function xml_extract { # TAGLIST FILE
	local -a tags=( ${1//:/ } )
	local fileIn="$2"
	local tmp
		
	# awkScript: 
	# /<tag/,/<\/tag/ {           # get all lines between <tag> and </tag>
	# 	sub( ".*<tag[^>]*>", "")  # remove starting <tag> 
	#   sub( "</tag[^>]*>.*", "") # remove ending </tag>
	#	print }                   # print result
	#
	tag=${tags[0]}
	tmp="$( awk '/<'${tag}'/,/<\/'${tag}'/ {sub(".*<'${tag}'[^>]*>",""); sub("</'${tag}'[^>]*>.*","");  print}' ${fileIn} )"
	
	# if tags are nested
	if (( ${#tags[@]} > 1 )) ; then
		for tag in ${tags[@]:1} ; do
			tmp="$( echo ${tmp} | awk '/<'${tag}'/,/<\/'${tag}'/ {sub(".*<'${tag}'[^>]*>",""); sub("</'${tag}'[^>]*>.*","");  print}' - )"
		done
	fi

	tmp=( ${tmp} ) # trim all spaces
	echo ${tmp[@]}

	return
}


#==============================================================================
# xml_extractMultiElements - extraction of multiple values from one XML file
#
# SYNOPSIS
#	xml_extract FILE TAGLIST [TAGLIST ...]
#
# DESCRIPTION
#	This function extracts values from an XML file.
#
# OPTIONS
#	FILE    A file name
#	TAGLIST   A colon-separated list of nested tags defining the element
#
# EXAMPLE
#	The XML file may contain lines like
#	<My_Report>
#		<report_header>
#			<cmd_id>4711</cmd_id>
#			<cmd_name>design_a_perfume</cmd_name>
#		</report_header>
#		[...]
#	</My_Report>
#
#	xml_extract report.xml "report_header:cmd_id" "report_header:cmd_name"
#		This will extract the value `4711` which is found within the cmd_id tags,
#		which itself is found between the report_header tags and in a second
#		run it extracts the value `design_a_perfume` which is found within the
#		cmd_name tags which itself is found between the report_header tags.
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.081120===

function xml_extractMultiElements { # FILE TAGLIST [TAGLIST ...]
	local fileIn="$1"
	shift 

	for tagList in $@ ; do
		xml_extract "$tagList" "$fileIn"
	done
	
	return
}


#==============================================================================
# xml_extractMultiFiles - extraction of one element from multiple XML files
#
# SYNOPSIS
#	xml_extractMultiFiles [-d DELIM | -q] TAGLIST FILE [FILE ...]
#
# DESCRIPTION
#	This function extracts one element from multiple XML files. The results are
#	preceded by the file name and a ":" (colon) as delimiter unless the -d or -q
#   option was used.
#
# OPTIONS
#	-d DELIM  Sets the output delimiter, defaults to ":". Use "\n" for new-line.
#	-q        Suppresses the printing of the file name
#	TAGLIST   A colon-separated list of nested tags defining the element
#	FILE      One or more file names
#
# EXAMPLE
#	Two XML files may contain lines like
#	<My_Report>
#		<report_header>
#			<cmd_id>4711</cmd_id>
#			<cmd_name>design_a_perfume</cmd_name>
#		</report_header>
#		[...]
#	</My_Report>
#
#	<My_Report>
#		<report_header>
#			<cmd_id>1000</cmd_id>
#			<cmd_name>stink_like_hell</cmd_name>
#		</report_header>
#		[...]
#	</My_Report>
#
#	xml_extractMultiFiles "report_header:cmd_id" report*.xml
#		This will extract the value of the cmd_id tags from all XML files that
#		match the glob pattern "report*.xml". The result will be like
#
#			report_cologne.xml:4711
#			report_berlin.xml:1000
#
#	xml_extractMultiFiles -d "\tfoo\nbar: " "report_header:cmd_id" report*.xml
#		Same as above except that the delimiter was set to 
#		"TAB"+"foo"+"NEWLINE"+"bar:"+"SPACE". The result will be like
#
#			report_cologne.xml	foo
#			bar: 4711
#			report_berlin.xml	foo
#			bar: 1000
#
#	xml_extractMultiFiles -q "report_header:cmd_id" report*.xml
#		Same as above except that the file names are not listed. The result
#		will be like
#
#			4711
#			1000
#
# AUTHOR
#	Andreas Tusche (bash-libraries@andreas-tusche.de) 
#===================================================================V.081120===

function xml_extractMultiFiles { # [-d DELIM | -q ] TAGLIST FILES
	local dlm=":" quiet=0

	if [[ "$1" == "-d" ]] ; then dlm="$2" ; shift 2 ; fi
	if [[ "$1" == "-q" ]] ; then quiet=1  ; shift   ; fi
	if [[ "$dlm" == "" ]] ; then quiet=1            ; fi

	local taglist="$1"
	shift 

	for fileIn in $@ ; do
		(( $quiet )) || echo -en "${fileIn}${dlm}"
		xml_extract "$taglist" "$fileIn"
	done
	
	return
}


###############################################################################
# Cleanup and return
###############################################################################

declare -Fr xml_extract
declare -Fr xml_extractMultiElements
declare -Fr xml_extractMultiFiles
readonly xml_lib_loaded=1
return $ERR_NOERR

###############################################################################
# END
###############################################################################

#--------------------------------------------------------------------------
# simple XML parser, store values in array val[]
#--------------------------------------------------------------------------
awkParseXMLReport='
	BEGIN {
		FS="[<>]"  # separate tags and values
		RS=">"     # use tag-end as record end, ignore new lines
		SUBSEP="::"
		_xml_dim=0 # init
	}

	$1 !~ /^[\n\t ]*$/ {                                    # found a non-empty line
		_xml_idx = _xml_tag[1]
		for (_xml_i=2; _xml_i<=_xml_dim;_xml_i++)
			_xml_idx = _xml_idx SUBSEP _xml_tag[_xml_i] # compile index
		gsub("^[ \n\t]+|[ \n\t]+$", "", $1) # remove trailing spaces
		# print "val[" _xml_idx " ]=" $1 # DEBUG
		val[_xml_idx] = $1 # store value in val[index]
	}

	$2 ~ /^[-A-Za-z0-9_]+$/ { _xml_tag[++_xml_dim] = $2 }   # found a tag start
	$2 ~ /^\// {       delete _xml_tag[_xml_dim--]      }   # found a tag end

	END { for (i in val) print "val[" i "]=" val[i] }
'
