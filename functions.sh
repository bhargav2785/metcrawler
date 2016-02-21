#!/bin/bash

DEPENDENCIES_RESOLVED=true;

function check_dependency(){
	if ! which $1 > /dev/null; then
		echo "Please install $1 or make sure it is in your path";
		echo "See $2";
		echo "";
		DEPENDENCIES_RESOLVED=false;
	fi
}

urlencode() {
	local string="${1}"
	local strlen=${#string}
	local encoded=""

	for (( pos=0 ; pos<strlen ; pos++ )); do
		c=${string:$pos:1}
		case "$c" in
			[-_.~a-zA-Z0-9] ) o="${c}" ;;
			* )               printf -v o '%%%02x' "'$c"
		esac
		encoded+="${o}"
	done

	echo "${encoded}"
}

printHeader(){
	consolePrint ""
	consolePrint "##########################################################"
	consolePrint "$1"
	consolePrint "##########################################################"
	consolePrint ""
}

printUsage(){
	consolePrint "Usage : ./metcrawler.sh http://www.example.com [mobile|desktop]"
	consolePrint "        1. Do not include slash at the end"
	consolePrint "        2. Make sure your site begins with either http:// or https://"
	consolePrint "        3. Try including/excluding www"
}

printError(){
	consolePrint "ERROR : $1."
}

printNotice(){
	consolePrint "NOTICE : $1."
}

consolePrint(){
	echo `date '+%H:%M:%S'` " $1"
}