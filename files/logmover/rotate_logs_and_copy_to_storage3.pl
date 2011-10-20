#!/usr/bin/perl
# What? See http://wikitech.wikimedia.org/view/Fundraising_Analytics/Impression_Stats
use strict;
use Sys::Syslog;
use File::Copy 'move';

# to do:
# - some sort of quota/sanity check for $transfer_dir
# - consider more intentional notification rather than generic cronspam

# local dir where udp2log collects logs
my $udp2log_dir = '/a/squid/fundraising/logs';

# local dir where we move logs for sending to long term storage
my $transfer_dir = "$udp2log_dir/destined_for_storage3";

# remote dir where we queue logs for storage-side gzipper script
my $remote_dir = 'logmover@storage3.pmtpa.wmnet:/archive/incoming_udplogs';

# binary that induces a udp2log reset
my $resetudp2log = '/home/file_mover/scripts/resetudp2log';

# list of log files (sans extension) to rotate
my @logs_to_process = qw(landingpages bannerImpressions);

# my ident string for use in syslog
my $ident = $0;

# turn off output buffering, probably unnecessary
$|=1;

# remove logs from the transfer dir if they've been removed (processed) on the storage host
printlog("rsync -a --delete --ignore-non-existing --ignore-existing $remote_dir/ $transfer_dir/");
open CMD, "rsync -a --delete --ignore-non-existing --ignore-existing $remote_dir/ $transfer_dir/ 2>&1|";
while (<CMD>) {
	chomp;
	failboat($_) if /\((1|2|3|4|5|6|10|11|12|13|14|20|21|22|23|25|28|30|35)\)$/;
	failboat($_) if /(unexpectedly closed|unexplained error)/;
	printlog($_) if /^(sent|total)/;
}
close CMD;

# make sure we have a usable resetudp2log
failboat("$resetudp2log is missing") unless (-e $resetudp2log);
failboat("$resetudp2log is not executable") unless (-x $resetudp2log);

# rotate/rename logs
my $logs_to_rsync;
for my $file (@logs_to_process) {
	if (-e "$udp2log_dir/$file.log") {	
		my $date = `/bin/date +%Y-%m-%d-%I%p--%M`;
		chomp $date;
		printlog("move $udp2log_dir/$file.log to $transfer_dir/$file-$date.log");
		move("$udp2log_dir/$file.log", "$transfer_dir/$file-$date.log") or failboat($!);
		printlog('reload udp2log');
		`/home/file_mover/scripts/resetudp2log`;
		$logs_to_rsync++;
	} else {
		printlog("didn't find $udp2log_dir/$file.log?!");
	}
}

# copy newly rotated logs to storage host
if (defined $logs_to_rsync) {
	printlog("rsync -ar $transfer_dir/ $remote_dir/");
	open CMD, "rsync -ar $transfer_dir/ $remote_dir/ 2>&1|";
	while (<CMD>) {
		chomp;
		failboat($_) if /\((1|2|3|4|5|6|10|11|12|13|14|20|21|22|23|25|28|30|35)\)$/;
		failboat($_) if /(unexpectedly closed|unexplained error)/;
		printlog($_) if /^(sent|total)/;
	}		
	close CMD;
}

# somewhere like here we should do a quota check and email if bloatworthy

printlog('done!');

exit;


#         _                 _   _             
# ____  _| |__ _ _ ___ _  _| |_(_)_ _  ___ ___
#(_-< || | '_ \ '_/ _ \ || |  _| | ' \/ -_|_-<
#/__/\_,_|_.__/_| \___/\_,_|\__|_|_||_\___/__/
#                                             

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
