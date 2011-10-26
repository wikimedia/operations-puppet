#!/usr/bin/perl
# What? See http://wikitech.wikimedia.org/view/Fundraising_Analytics/Impression_Stats
use strict;
use Sys::Syslog;
use File::Copy 'move';
use File::Find;
use IO::Compress::Gzip qw(gzip $GzipError);

# local dir where we receive uncompressed logs
my $incoming_dir = "/archive/incoming_udplogs";

# local dir where we store compressed logs long term
my $store_dir = "/archive/udplogs";

# my ident string for use in syslog
my $ident = 'gzip_incoming_logs';

# turn off output buffering, probably unnecessary
$|=1;

# walk the input directory and go process stuff
find(\&process_file, $incoming_dir);

printlog('done!');

exit;


#         _                 _   _             
# ____  _| |__ _ _ ___ _  _| |_(_)_ _  ___ ___
#(_-< || | '_ \ '_/ _ \ || |  _| | ' \/ -_|_-<
#/__/\_,_|_.__/_| \___/\_,_|\__|_|_||_\___/__/
#                                             


sub process_file {
	my $shortname = $_;
	return unless -f $File::Find::name; # process only files, not dirs, symlinks . . .
	return if $shortname =~ /^\./;		# don't process hidden files
	if ($shortname =~ /gz$/) {
		# just move if file is already gzipped
		move($File::Find::name, "$store_dir/") or failboat($!);
		printlog("moved $File::Find::name to $store_dir");
	} else {
		# not gzipped? gzip to long term storage then delete
		gzip $File::Find::name => "$store_dir/$shortname.gz" or failboat("gzip failed: $GzipError");
		unlink $File::Find::name;
		printlog("gzipped $File::Find::name to $store_dir/$shortname.gz");
	}	
}

sub failboat {
	my $msg = shift;
	print "$ident died: $msg\n";
	printlog("died: $msg");
	exit 1;
}

sub printlog {
	my $msg = $_[0] ? $_[0] : '';
	my $severity = $_[1] ? $_[1] : 'info'; # notice warning error etc.
	Sys::Syslog::setlogsock('unix');
	Sys::Syslog::openlog($ident,'ndelay,pid','user');
	Sys::Syslog::syslog($severity,$msg);
	Sys::Syslog::closelog();
}
