# NutchStats
Scripts for generating page stats from a Nutch crawl.

## Overview

This is a set of scripts for generating a CSV file of per page stats of a single website crawl with Nutch, like one would use for a content audit. It was developed against [Nutch 1.11](http://nutch.apache.org/), but may work with other versions.

## Quickstart

Assuming you have generated a Nutch crawl via the crawl command, e.g.

    bin/crawl urls/ MyCrawl 4

you can generate a dump of per page stats via the commands:

    perl makedump.pl MyCrawl
    perl processcrawl.pl MyCrawl 4

The output is a CSV file with the following fields:

    Url, Type, Extension, Host, Title, Word Count, In Links Count, Out Links Count, Self Links Count, Crawl Status, Depth, Visit Count

For more information on generating the Visit Count field, see the Visit Counts section below.

## Usage

### makedump.pl

    Usage: makedump.pl <Crawl Directory>
    	Crawl Directory: Name of crawl directory given as 2nd argument to nutch's bin/crawl

### processcrawl.pl

    Usage: processcrawl.pl <Crawl Directory> <N Segments> [Visit File] [Host]
    	Crawl Directory: Name of the crawl directory given as 2nd argument to nutch's bin/crawl.
    	N Segments: Number of segments (3rd argument to bin/crawl)
    	Visit File: (Optional) File of visit counts from web site.
    	Host: (Optional for processing visit file) Host name to append to visit counts (without ending slash).


## Crawling with Nutch

If you are doing a content inventory, you will probably want to change some of the default Nutch settings. The primary place where Nutch settings are configured are nutch-default.xml (or nutch-site.xml if you want site-specific rules separated from the default rule set) and regex-urlfilter.txt. 

N.B. The versions of the config files that should be edited are the ones located runtime/local/conf, not the ones in the top level conf directory of the distribution.

### Agent name

You must set an agent name (http.agent.name) for your agent in order for the crawl to work. Reference Nutch documentation for more details about this.

### Internal Links

By default Nutch will not add internal links to the links database. In order to be able to count in links from within your website, you must change db.ignore.internal.links to false.

### Max Outlinks 

By default Nutch limits the number of Outlinks that will be processed for a page to 100. For a full content inventory, set db.max.outlinks.per.page to -1. 

### Host whitelist

You may want to ignore robot rules for the host you are crawling in order to get a full inventory of your site. This is controlled with the http.robot.rules.whitelist setting. This feature should be used very carefully. Also note that in Nutch 1.11, the robot whitelist feature that will ignore robots.txt is broken. In order to get this to work, check out a snapshot release from the Nutch repository.

### Regex Filtering

By default, Nutch skips URLs with image and document suffixes. If you want to see these files in your crawl, modify the regex filter in regex-urlfilter.txt to remove the appropriate extensions (gif/GIF/jpg/JPG/etc.).

If you only want to crawl one domain, you should remove the "accept anything else" rule from the end of the regex filter list in regex-urlfilter.txt and add a rule that limits to your domain and/or its subdomains. E.g.

    # Filter out the data subdomain of my site
    -^http://data.mysite.org/
    # Allow from any other subdomain of my site
    +^http://.*.mysite.org/
    

## Visit Counts from Apache

The script is designed to incorporate visit counts from an Apache log when given a preprocessed file of counts and URLs as would be output by a command line uniq -c. To generate this file from a directory of log files, for example from a single month (6/2015), we generate this file using the command line as follows.

    cut -f4,5 logs/access_log_2015-06-* | grep -v POST | grep -v OPTIONS | cut -f2 | sort | uniq -c > visited-raw-june-2015.txt

Note: The format of your log file and log file name may vary.

To process the crawl with the log file information, run

    perl makedump.pl MyCrawl
    perl processcrawl.pl MyCrawl 4 visited-raw-june-2015.txt http://yourhostname.com

The final argument appends the host name to the log file path so that the URLs can be matched up with the crawl, since typically this isn't present.


