# MetCrawler

## Introduction
MetCrawler is a web performance metrics crawler for a website. It uses the data hosted by http://httparchive.org and http://www.webpagetest.org/.
 
## Where to use this tool?
MetCrawler downloads performance data of a given website from http://httparchive.org. HttpArchive project has these data available from late 2010 or early 2011 for most of the sites. If the site is available in http://httparchive.org project then running this script will download two files 1) metrics.csv and 2) metrics.json. You can use whichever format you prefer. You can feed this data to some charts and see how did the website performance metrics evolved over the time. If you are doing an audit or an analysis of your website and trying to figure out performance gain/lose, this tool could be useful.

## What is in the metric file?
Both metrics.csv and metrics.json contains the same data but in different format for various projects. The file contains given websites web performance data. Some of the popular metrics are TTFB, firstPaintTime, loadTime, documentCompleteTime, speedIndex, connectionCount, js_size, css_size etc.

## How does it work?
MetCrawler queries HttpArchive project and gets the dates on which the tests(webpagetests) were run on HttpArchive project. After that, the tool queries WebPageTest and gets the performance data for each run found from the HttpArchive.

## Requirements
There is no special requirements expect it needs following command-line tools installed.

* ``` curl ```
* ``` jq ```
* ``` pup ```
* ``` csvjson ```

If you haven't installed them or not sure about them don't worry. The script will check for the dependencies and let you know sources where you can download/install them.
  
## How to use it?
It is really simple shell script and you can invoke it with two arguments.

- website name (name of the website you need metrics for)
- type (mobile/desktop)

Below are some of the examples. If anything is wrong, the script will guide you step by step on what is missing.

* ```./metcrawler.sh (invalid example, website name is required)```
* ```./metcrawler.sh http://www.google.com (valid example)```
* ```./metcrawler.sh http://www.google.com mobile (valid example)```
* ```./metcrawler.sh http://www.google.com desktop (valid example)```
* ```./metcrawler.sh www.google.com desktop (invalid example, http or https is required)```
* ```./metcrawler.sh google.com desktop (invalid example, http or https is required)```

The tool produces human readable debug messages so you will know what's exactly happening while running the script.

## Change Log
2016.02.19 Initial version