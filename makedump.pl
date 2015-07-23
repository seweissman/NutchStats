$usage = "Usage: makedump.pl <Crawl Directory>\n"
    . "\tCrawl Directory: Name of crawl directory given as 2nd argument to nutch's bin/crawl\n";

if($#ARGV < 0){
    die "$usage";
}

my $crawl = $ARGV[0];

print "Dumping crawl: $crawl\n";
my $crawldbdumpdir = "${crawl}Crawl";
my $linkdbdumpdir = "${crawl}Links";
print "bin/nutch readdb $crawl/crawldb/ -dump $crawldbdumpdir","\n";
`bin/nutch readdb $crawl/crawldb/ -dump $crawldbdumpdir`;
print "bin/nutch readlinkdb $crawl/linkdb/ -dump $linkdbdumpdir","\n";
`bin/nutch readlinkdb $crawl/linkdb/ -dump $linkdbdumpdir`;
opendir(DIR, "$crawl/segments") || die;
@segfiles = readdir(DIR);
closedir(DIR);
my $segct = 1;
foreach $file (@segfiles){
    if($file eq "." || $file eq ".."){
	next;
    }
    print "bin/nutch readseg -dump $crawl/segments/$file ${crawl}Seg${segct}","\n";
    `bin/nutch readseg -dump $crawl/segments/$file ${crawl}Seg${segct}`;
    $segct += 1;
}




