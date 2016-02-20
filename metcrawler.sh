#!/bin/bash

#######################################
# handle multiple sites as in www.google.com
#######################################

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

processRun(){
	JSON_FULL="$1"
	metricName="$2"
	METRICS="$3"
	testId="$4"
	completed="$5"

	JSON=$( echo ${JSON_FULL} | jq ".data.${metricName}" )
	JSON_LEN=$(echo ${JSON} | jq '.firstView | length')

	if [ ${JSON_LEN} -gt 0 ]; then
		VALUES="";
		for metric in ${METRICS}; do
			METRIC_VALUE=$( echo ${JSON} | jq ".firstView[\"${metric}\"]" );
			VALUES="${VALUES}${METRIC_VALUE},";
		done

		echo ${metricName},${testId},${completed},${VALUES} >> metrics.csv;
	else
		printNotice "No ${metricName}.firstView data found for test_id: ${test} ... skipping"
	fi
}

printHeader "Checking dependencies"
check_dependency jq "https://stedolan.github.io/jq/download/ or run (brew install jq)"
check_dependency curl "https://curl.haxx.se/docs/manpage.html or run (brew install curl)"
check_dependency csvjson "http://csvkit.readthedocs.org/en/0.9.1/install.html or run (pip install csvkit)"
check_dependency pup "https://github.com/ericchiang/pup or run (brew install https://raw.githubusercontent.com/EricChiang/pup/master/pup.rb)"

# dependency check
if [ ${DEPENDENCIES_RESOLVED} != true ]; then
	printError "Please resolve all dependencies listed above";
	exit;
fi

# remove file if exist
rm -f metrics.csv
rm -f metrics.json

if [ -n "$1" ]; then
	SITE="$1";
	REGEXP="https?://([^/]+)"
	if ! [[ ${SITE} =~ ${REGEXP} ]]; then
		printError "Url pattern is not valid"
		printUsage
		exit
	fi
else
	printError "Please provide a site name"
	printUsage
	exit
fi

DOMAIN_PREFIX=""

if [ -n "$2" ]; then
	RUN_TYPE=$( echo "$2" | tr 'A-Z' 'a-z' )
	if [ 'mobile' != "${RUN_TYPE}" ] && [ 'desktop' != "${RUN_TYPE}" ]; then
		printError "Invalid second argument. It needs to be either 'mobile' or 'desktop' or nothing"
		printUsage
		exit
	fi
	if [ 'mobile' = "${RUN_TYPE}" ]; then
		DOMAIN_PREFIX="mobile."
	fi
fi

printHeader "Quering httparchive.org for ${SITE}"

RESULTS=$( curl -s "http://${DOMAIN_PREFIX}httparchive.org/findurl.php?term=${SITE}/" );
RESULT_LENGTH=$( echo ${RESULTS} | jq '. | length' )

if [ 0 -eq ${RESULT_LENGTH} ]; then
	consolePrint "Site '${SITE}' not found"
	printUsage
	exit
elif [ ${RESULT_LENGTH} -gt 1 ]; then
	consolePrint "Site '${SITE}' has multiple matches"
	exit
else
	consolePrint "Site '${SITE}' found"
fi

printHeader "Quering httparchive.org for available runs"
PAGE_ID=$( echo ${RESULTS} | jq -r '.[0]["data-pageid"]' )
RUNS=$( curl -s "http://${DOMAIN_PREFIX}httparchive.org/viewsite.php?pageid=${PAGE_ID}" | pup 'select json{}' | jq '.[0].children[] .text' | tr -d '"' | tr ' ' ',' )

TEST_IDS=()
for run in ${RUNS}; do
	P1=$( urlencode "${SITE}/" )
	L=$( echo ${run} | tr ',' ' ')
	P2=$( urlencode "${L}" )
	URL="http://${DOMAIN_PREFIX}httparchive.org/viewsite.php?u=${P1}&l=${P2}"
	WP_URL=$( curl -s ${URL} | pup '.horizlist a json{}' | jq -r '.[0].href' | cut -d'=' -f2 | cut -d':' -f1 | cut -d'-' -f1)
	TEST_IDS+=(${WP_URL})

	consolePrint "${run} => ${WP_URL}"
done

printHeader "Collecting metrics(avg,std_dev,med) for each test runs"
METRICS="TTFB adult_site aft avgRun bytesIn bytesInDoc bytesOut bytesOutDoc cached connections date docCPUms docCPUpct docTime domContentLoadedEventEnd domContentLoadedEventStart domElements domTime effectiveBps effectiveBpsDoc firstPaint fixed_viewport fullyLoaded fullyLoadedCPUms fullyLoadedCPUpct gzip_savings gzip_total image_savings image_total isResponsive lastVisualChange loadEventEnd loadEventStart loadTime minify_savings minify_total optimization_checked pageSpeedVersion render requestsDoc requestsFull responses_200 responses_404 responses_other result run score_cache score_cdn score_combine score_compress score_cookies score_etags score_gzip score_keep-alive score_minify score_progressive_jpeg server_count server_rtt titleTime";

echo "measure,id,date,"${METRICS} | tr ' ' ',' >> metrics.csv

for test in "${TEST_IDS[@]}"; do
	consolePrint "processing ${test}"

	JSON_FULL=$( curl -s "http://httparchive.webpagetest.org/jsonResult.php?test=${test}" )
	CODE=$( echo ${JSON_FULL} | jq -r '.statusCode' )
	COMPLETED=$( echo ${JSON_FULL} | jq -r '.data.completed' )

	if [ 200 != ${CODE} ]; then
		printNotice "No data found for test_id: ${test} ... skipping test"
		continue
	fi

	processRun "${JSON_FULL}" "average" "${METRICS}" "${test}" "${COMPLETED}"
	processRun "${JSON_FULL}" "standardDeviation" "${METRICS}" "${test}" "${COMPLETED}"
	processRun "${JSON_FULL}" "median" "${METRICS}" "${test}" "${COMPLETED}"
done

printHeader "Creating metrics.json"
csvjson -i 4 metrics.csv > metrics.json
consolePrint "Finished"