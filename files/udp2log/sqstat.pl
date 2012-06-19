#!/usr/bin/env perl
#
# process wmf cache server log lines via stdin and report to ganglia
#
# * counts all requests in total, and uniquely for upload.wikimedia
#
# * counts pageviews (/wiki/..) for all properties and colects frontend
#   time for 1% of received paged view requests
#
# * counts all edit requests for all properties and collects
#   timing data for all
#
# This was rewritten in perl because the original python version was
# significantly slower, even though it did much less (only collected stats
# on 20 properties, and didn't track edits, mobile, uploads, or have
# latency bucket sampling.  Even when rewritten in horid ways and
# stripped further, and even when compiled into C++. This is 2-3x
# faster than the most stripped down compiled python version but does
# a lot more.  And I didn't want to write this in C.
#
# sample squid log line:
# sq40.wikimedia.org 1200534271 2011-06-22T00:06:48.771 490 123.05.05.05 TCP_MISS/200 7196 GET http://en.wikipedia.org/wiki/Category_talk:New_Jersey_District_Factor_Groups CARP/208.80.152.71 text/html - - Mozilla/5.0%20(compatible;%20bingbot/2.0;%20+http://www.bing.com/bingbot.htm)
#

use strict;
use warnings;
use Data::Dumper;
use IO::Socket::INET;
use POSIX qw(ceil);

$0 = "/usr/local/bin/sqstat";

my $carbon_server = "10.0.6.30";
my $carbon_port = 2003;
my $carbon = IO::Socket::INET->new(
	PeerAddr => $carbon_server,
	PeerPort => $carbon_port,
	Proto    => 'udp',
	Blocking => 0,
);

my $mult = $ARGV[0] || 1;

my %d = ( '4xx' => 0, '5xx' => 0, '500' => 0, 'requests' => 0, 'pageviews' => 0,
	'upload_requests' => 0, 'ssl_requests' => 0, 'mobile_pageviews' => 0 );
my @dkeys = keys %d;
my %p = (); # article page views by wiki
my %e = (); # edits by wiki
my $t = time();

my $line;
my $l=0;

$| = 1;

sub calctp() {
	my @times = sort { $a <=> $b } @{$_[0]};
	return (  $times[int(@times*0.5)], $times[int(@times*0.99)] );
}

sub send_metrics() {
	for my $key (@dkeys) {
		$carbon->send( "reqstats.$key $d{$key} $t\n" );
		$d{$key} = 0;
	}
	for my $key (keys %p) {
		my $name = $key;
		$name =~ s/\./_/g;

		$carbon->send( "reqstats.$name.pageviews $p{$key}{'hit'} $t\n" );
		if ( $p{$key}{'time'} ) {
			my ( $tp50, $tp99 ) = &calctp( \@{$p{$key}{'time'}} );
			$carbon->send( "reqstats.$name.tp50 $tp50 $t\n" );
			$carbon->send( "reqstats.$name.tp99 $tp99 $t\n" );
		}
	}
	for my $key (keys %e) {
		my $name = $key;
		$name =~ s/\./_/g;

		if ($e{$key}{'edit'}) {
			$carbon->send( "reqstats.edits.$name.edit $e{$key}{'edit'} $t\n" );
		}
		if ($e{$key}{'submit'}) {
			$carbon->send( "reqstats.edits.$name.submits $e{$key}{'submit'} $t\n" );
		}
		my ($tp50, $tp99) = &calctp(\@{$e{$key}{'time'}});
		$carbon->send( "reqstats.edits.$name.tp50 $tp50 $t\n" );
		$carbon->send( "reqstats.edits.$name.tp99 $tp99 $t\n" );
	}
}

while ($line = <STDIN>) {
	$l++;
	if ($line =~ / [\w_]+\/(\d{3}) /) {
		if ($1 >= 400 && $1 < 500) {
			$d{'4xx'} += $mult;
		} elsif ($1 > 500 && $1 <600) {
			$d{'5xx'} += $mult;
		} elsif ($1 == 500) {
			$d{'500'} += $mult;
		}
		$d{'requests'} += $mult;
	}
	if ($line =~ /^ssl/) {
		$d{'ssl_requests'} += $mult;
		next;
	}
	if ($line =~ /^\S+ \S+ \S+ \S+ \S+ \S+ \S+ \S+ http:\/\/upload.wik/) {
		$d{'upload_requests'} += $mult;
	} elsif ($line =~ /^\S+ \S+ \S+ (\S+) \S+ \S+ \S+ (GET|POST) http:\/\/([\w.]+org)\/(wiki|w)\/(\S+) /) {
		my $time = $1;
		my $method = $2;
		my $wiki = $3;
		my $root = $4;
		my $extra = $5;
		if ($root eq "wiki") {
			$d{'pageviews'} += $mult;
		} elsif ($extra =~ /^index.php/) {
			$d{'pageviews'} += $mult;
		} else {
			next;
		}
		if ($wiki =~ /\.m\./) {
			$d{'mobile_pageviews'} += $mult;
			$time *= 1000;
		}
		$p{$wiki}{'hit'} += $mult;
		if ($extra =~ /action=(edit|submit)/) {
			if ($1 eq "edit") {
				$e{$wiki}{'edit'} += $mult;
			} elsif ($method eq "POST") {
				$e{$wiki}{'submit'} += $mult;
			}
			push ( @{$e{$wiki}{'time'}}, $time );
		} elsif ($l % 100 == 0) {
			push ( @{$p{$wiki}{'time'}}, $time );
		}
	}

	if ($l >= 5000 / $mult) {
		$l = 0;
		if ($t + 60 <= time()) {
			$t = time();
			send_metrics();
			%p = (); # article page views by wiki
			%e = (); # edits by wiki
		}
	}
}
send_metrics();
