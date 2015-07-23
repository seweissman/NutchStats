$usage = "Usage: processcrawl.pl <Crawl Directory> <N Segments> [Visit File] [Host]\n"
	. "\tCrawl Directory: Name of the crawl directory given as 2nd argument to nutch's bin/crawl.\n"
	. "\tN Segments: Number of segments (3rd argument to bin/crawl)\n"
	. "\tVisit File: (Optional) File of visit counts from web site.\n"
	. "\tHost: (Optional for processing visit file) Host name to append to visit counts (without ending slash).\n";

if($#ARGV < 1){
    die $usage;
}

my $crawl = $ARGV[0];
my $segments = $ARGV[1];

print STDERR "Processing crawl: $crawl\n";
my $crawldumpfile = "${crawl}Crawl/part-00000";
my $linkdumpfile = "${crawl}Links/part-00000";
my $visitfile = $ARGV[2];
my $hostname = $ARGV[3];
#my $visitfileraw = $ARGV[3];

if(! -e $crawldumpfile || ! -e $linkdumpfile){
    die "Crawl dump files does not exist. Make sure to run makedump.pl before running processcrawl.pl. \n";
}

open(FILEIN, "<$crawldumpfile");

my %urls;
my $urlct = 0;
while($line = <FILEIN>){
    chomp $line;
    if($line =~ /^(.*)\tVersion: \d+/){
	$url = $1;
	$urls{$url} = {};
	$url =~ /http:\/\/([^\/]+)\/.*/;
	$host = $1;
	$urls{$url}->{Host} = $host;
	$urlct += 1;
	if($url =~ /http:\/\/[^\/]+\/.*\.([^.\/]+)$/){
	    $ext = $1;
	    $urls{$url}->{Extension} = $ext;
	}
	if($url =~ /\.(content|CONTENT|gz|GZ|z|Z|dat|DAT)$/){
	    $urls{$url}->{Type} = "DATA";
	}
	if($url =~ /\.(avi|AVI|mov|MOV|mp3|MP3)$/){
	    $urls{$url}->{Type} = "VIDEO";
	}
	if($url =~ /\.(htm|HTM|html|HTML|aspx|ASPX|asmx|ASMX)$/){
	    $urls{$url}->{Type} = "HTML";
	}
	if($url =~ /\.(js|JS|css|CSS)$/){
	    $urls{$url}->{Type} = "MARKUP";
	}
	if($url =~ /\.(jar|JAR|cgi|CGI|hqx)$/){
	    $urls{$url}->{Type} = "APP";
	}
	if($url =~ /\.(jpg|JPG|jpeg|JPEG|gif|GIF|ico|ICO|bmp|BMP|png|PNG|eps|EPS)$/){
	    $urls{$url}->{Type} = "IMAGE";
	}
	if($url =~ /\.(pdf|PDF|doc|DOC|txt|TXT|ps|PS|ppt|PPT|pptx|PPTX)$/){
	    $urls{$url}->{Type} = "DOC";
	}


    }
}
close(FILEIN);
my %visitct;
if($visitfile){
    open(FILEIN,"<$visitfile");
    while($line = <FILEIN>){
	chomp $line;
	$line =~ /^\s*(\d+)\s+(.*)$/;
	$ct = $1;
	$path = $2;
	$url = "$hostname$path";
	$visitct{$url} = $ct;
    }
    close(FILEIN);
}

# my %visitctraw;
# open(FILEIN,"<$visitfileraw");
# while($line = <FILEIN>){
#     chomp $line;
#     $line =~ /^\s*(\d+)\s+(.*)$/;
#     $ct = $1;
#     $path = $2;
#     $url = "$hostname$path";
#     $visitctraw{$url} = $ct;
# }
# close(FILEIN);

#print STDERR "URL count $urlct\n";

my $doContent = 0;
my $doParseText = 0;
my $doParseData = 0;
my $doCrawlDatum = 0;
my $recordNum = 0;
my $ref;
for($i=1;$i<=$segments;$i++){
    $ref = 0;
    $segdumpfile = "${crawl}Seg$i/dump";
    #print STDERR "Segdumpfile: $segdumpfile\n";
    open(FILEIN, "<$segdumpfile");
    while($line = <FILEIN>){
	if($line =~ /^Recno:: (\d+)$/){
	    if($ref){
		@outlinks = keys %outlinks;
		$outlinkct = $#outlinks + 1;
		if($outlinkct >= $ref->{OutLinks}){
		    $ref->{OutLinks} = $outlinkct;
		}
		if($selfoutlinksct >= $ref->{SelfLinks}){
		    $ref->{SelfLinks} = $selfoutlinksct;
		}
	    }
	    $selfoutlinksct = 0;
	    $recordNum = $1;
	    $doContent = 0;
	    $doParseText = 0;
	    $doParseData = 0;
	    $doCrawlDatum = 0;
	    $url = 0;
	    next;
	}
	if($line =~ /^URL:: (.*)$/){
	    $url = $1;
	    $ref = $urls{$url};
	    if(!(exists $ref->{Depth})){
		$ref->{Depth} = $i;
	    }
	    next;
	}
	if($line =~ /^Content::$/){
	    if(!$ref){
		print STDERR "No ref for url $url identified for Content in $segdumpfile\n";
	    }
	    $doContent = 1;
	    $doParseText = 0;
	    $doParseData = 0;
	    $doCrawlDatum = 0;
	    next;
	}
	if($line =~ /^ParseData::$/){
	    if(!$ref){
		print STDERR "No ref for url $url identified for ParseData in $segdumpfile\n";
	    }
	    %outlinks = {};
	    $doContent = 0;
	    $doParseText = 0;
	    $doParseData = 1;
	    $doCrawlDatum = 0;
	    next;
	}
	if($line =~ /^ParseText::$/){
	    if(!$ref){
		print STDERR "No ref for url $url identified for ParseText in $segdumpfile\n";
	    }
	    $doContent = 0;
	    $doParseText = 1;
	    $doParseData = 0;
	    $doCrawlDatum = 0;
	    next;
	}
	if($line =~ /^CrawlDatum::$/){
	    if(!$ref){
		print STDERR "No ref for url $url identified for CrawlDatum in $segdumpfile\n";
	    }
	    $doContent = 0;
	    $doParseText = 0;
	    $doParseData = 0;
	    $doCrawlDatum = 1;
	    next;
	}
	if($doContent){
	    if($line =~ /<title>(.*)<\/title>/){
		$title = $1;
		$ref->{Title} = $title;
	    }
	    if($line =~ /^contentType: (.*)$/){
		$type = $1;
		if($type =~ /image/){
		    $ref->{Type} = "IMAGE";
		}
		if($type =~ /javascript|css/){
		    $ref->{Type} = "MARKUP";
		}
		if($type =~ /pdf/){
		    $ref->{Type} = "DOC";
		}
		if($type =~ /html/){
		    $ref->{Type} = "HTML";
		}
		if($type =~ /x-php/){
		    $ref->{Type} = "APP";
		}
		if($type =~ /text\/plain/){
		    $ref->{Type} = "DOC";
		}
	    }
	    next;
	}
	if($doParseData){
	    if($line =~ /outlink: toUrl: (.*) anchor:/){
		$outlink = $1;
		if($outlink eq $url){
		    $selfoutlinksct += 1;
		}
		if(!($outlink =~ /\.(gif|css|js|jpeg|jpg|png|ico)$/)){
		    $outlinks{$outlink} = 1;
		}
	    }
	    next;
	}
	if($doParseText){
	    $text = $line;
	    @line = split(" ",$line);
	    $ref->{WordCount} = $#line + 1;
	    $doParseText = 0;
	    next;
	}
	if($doCrawlDatum){
	    if($line =~ /^Status: \d+ \((.*)\)$/){
		$status = $1;

		if($ref->{Status} eq "fetch_gone" ||
		   $ref->{Status} eq "fetch_success"){
		    next;
		}
		if($status eq "fetch_gone" ||
		   $status eq "fetch_success"){
		    $ref->{Status} = $status;
		    next;
		}
		if($ref->{Status} eq "db_unfetched"){
		    $ref->{Status} = $status;
		    next;
		}
		if($status eq "db_unfetched" && !$ref->{Status}){
		    $ref->{Status} = $status;
		    next;
		}
		if($ref->{Status} eq "linked" || $ref->{Status} eq "signature"){
		    $ref->{Status} = $status;
		    next;
		}
		$ref->{Status} = $status;
	    }
	}
    }
    close(FILEIN);
}

open(FILEIN, "<$linkdumpfile");
my $urlct = 0;
my $fromCt = 0;
my $selfinlinkct = 0;
$url = 0;
$ref = 0;
while($line = <FILEIN>){
    chomp $line;
    if($line =~ /^(.*)\tInlinks:/){
	$ref = $urls{$url};
	if(!$ref && $url){
	    die "No ref found for url $url\n";
	}else{
	    $ref->{InLinks} = $fromCt;
	}
	$selfinlinkct = 0;
	$url = $1;
	$fromCt = 0;
    }
    if($line =~ /fromUrl: (.*) anchor:/){
	$fromUrl = $1;
	if($fromUrl eq $url){
	    $selfinlinkct += 1;
	}else{
	    $fromCt += 1;
	}
    }

}
close(FILEIN);


foreach $url (keys %urls){
    print "$url,";
    if(exists $urls{$url}->{Type}){
	print $urls{$url}->{Type};
    }else{
	print "UNKNOWN";
    }
    print ",";
    if(exists $urls{$url}->{Extension}){
	print $urls{$url}->{Extension};
    }
    print ",";
    if(exists $urls{$url}->{Host}){
	print $urls{$url}->{Host};
    }
    print ",";
    if(exists $urls{$url}->{Title}){
	print "\"$urls{$url}->{Title}\"";
    }
    print ",";
    if(exists $urls{$url}->{WordCount}){
	print $urls{$url}->{WordCount};
    }
    print ",";
    if(exists $urls{$url}->{InLinks}){
	print $urls{$url}->{InLinks};
    }
    print ",";
    if(exists $urls{$url}->{OutLinks}){
	print $urls{$url}->{OutLinks};
    }
    print ",";
    if(exists $urls{$url}->{SelfLinks}){
	print $urls{$url}->{SelfLinks};
    }
    print ",";
    if(exists $urls{$url}->{Status}){
	print $urls{$url}->{Status};
    }
    print ",";
    if(exists $urls{$url}->{Depth}){
	print $urls{$url}->{Depth};
    }
    print ",";
    if(exists $visitct{$url}){
	print $visitct{$url};
    }
    # print ",";
    # if(exists $visitctraw{$url}){
    # 	print $visitctraw{$url};
    # }
    print "\n";
}
