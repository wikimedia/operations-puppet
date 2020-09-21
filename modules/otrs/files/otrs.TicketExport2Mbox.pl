#!/usr/bin/perl
#
# Copyright (c) 2013 Jeff Green <jgreen@wikimedia.org>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is furnished to do
# so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
use strict;

# default location to write mail
my $Mbox = "/tmp/mbox";
chomp(my $ident = ($0 =~ /([^\/]+)$/) ? $1 : $0);

use Sys::Syslog;
use File::Basename;
use FindBin qw($RealBin);
use lib dirname($RealBin);
use lib dirname($RealBin) . '/Kernel/cpan-lib';
use lib dirname($RealBin) . '/Custom';
use Getopt::Long;
use Kernel::Config;
use Kernel::System::DB;
use Kernel::System::Encode;
use Kernel::System::Log;
use Kernel::System::Main;
use Kernel::System::Ticket;
use Kernel::System::Time;
use Kernel::System::ObjectManager;

# create common objects
my (%CommonObject,$Close,$Help,@TicketIDs,@TicketNumbers,@ArticleIDs,$Rebuild);

local $Kernel::OM = Kernel::System::ObjectManager->new(
	'Kernel::System::Log' => {
		LogPrefix => 'OTRS-otrs.TicketExport2Mbox.pl',
	},
);

$CommonObject{ConfigObject}         = $Kernel::OM->Get('Kernel::Config');
$CommonObject{EncodeObject}         = $Kernel::OM->Get('Kernel::System::Encode');
$CommonObject{LogObject}            = $Kernel::OM->Get('Kernel::System::Log');
$CommonObject{TimeObject}           = $Kernel::OM->Get('Kernel::System::Time');
$CommonObject{MainObject}           = $Kernel::OM->Get('Kernel::System::Main');
$CommonObject{DBObject}             = $Kernel::OM->Get('Kernel::System::DB');
$CommonObject{TicketObject}         = $Kernel::OM->Get('Kernel::System::Ticket');
$CommonObject{ArticleObject}        = $Kernel::OM->Get('Kernel::System::Ticket::Article');
$CommonObject{ArticleBackendObject} = $Kernel::OM->Get('Kernel::System::Ticket::Article')->BackendForChannel(ChannelName => 'Email');

GetOptions(
	'close'               => \$Close,
	'help'                => \$Help,
	'mbox=s'              => \$Mbox,
	'TicketNumber=s{,}'   => \@TicketNumbers,
	'TicketID=s{,}'       => \@TicketIDs,
	'rebuild'             => \$Rebuild,
);

# when called from Generic Agent, ARG[0] is TicketNumber and ARG[1] is TicketID
if (($ARGV[0] =~ /^\d{16}/) and ($ARGV[1] =~ /^(\d+)/)) {
	my $TicketID = $1;
	chomp $TicketID;
	push @TicketIDs, $TicketID;
}

usage() if defined $Help;
usage() unless @TicketIDs or @TicketNumbers;

my ($Day,$Month,$Year) = ($CommonObject{TimeObject}->SystemTime2Date(
		SystemTime => $CommonObject{TimeObject}->SystemTime()
	))[3,4,5];

for my $TicketNumber (@TicketNumbers) {
	my $TicketID = $CommonObject{TicketObject}->TicketIDLookup(
		TicketNumber => $TicketNumber,
		UserID => 1,
		Silent => 0,
	);
	if (defined $TicketID) {
		push @TicketIDs, $TicketID;
	} else {
		printlog("Unable to find TicketNumber $TicketNumber.");	
	}
}

for my $TicketID (@TicketIDs) {
	my %HistoryData = $CommonObject{TicketObject}->HistoryTicketGet(
		StopYear => $Year,
		StopMonth => $Month,
		StopDay => $Day,
		TicketID => $TicketID,
		UserID    => 1,
		Silent => 0,
	);
	if (($HistoryData{'Queue'} eq 'Junk') and ($HistoryData{'CreateQueue'} eq 'Junk')) {
		printlog("Skip TicketID $TicketID, it was already autoqueued to Junk.",'debug');
	} elsif (($HistoryData{'State'} =~ /^closed successful$/) and (! defined $Rebuild)) {
		printlog("Skip TicketID $TicketID, it is already 'Closed successful'.",'debug');
	} else {
		my @TicketArticles = $CommonObject{ArticleObject}->ArticleList(
			TicketID => $TicketID,
			UserID => 1,
			Silent => 0,
		);
		if (@TicketArticles) {
			for my $Article (@TicketArticles) {
				eval {
					printArticle($Article->{ArticleID});
				};
				if ($@) {
					printlog("printArticle error: $@");
				}
			}
			closeTicket($TicketID) if defined $Close;
		} else {
			printlog("Unable to find articles for TicketID $TicketID.",'debug');
		}
	}
}

exit;




sub closeTicket {
	my $TicketID = shift;
	$CommonObject{TicketObject}->StateSet(
		TicketID => $TicketID,
		State => 'Closed successful',
		UserID => 1,
		Silent => 0,
	);
	OTRSLog("TicketID $TicketID state changed to 'Closed successful'.",'debug');
}

sub printArticle {
	my $ArticleID = shift;
	my $PlainMessage = $CommonObject{ArticleBackendObject}->ArticlePlain(
		ArticleID => $ArticleID,
		UserID => 1,
		Silent => 0,
	);
	if (defined $PlainMessage) {
		my $CleanPlainMessage = cleanupArticle($PlainMessage);
		if (open MBOX, ">> $Mbox") {
			print MBOX "$CleanPlainMessage\n";
			close MBOX;
			printlog("ArticleID $ArticleID written to $Mbox.",'debug');
		} else {
			printlog("can't write to $Mbox.",'error');
			exit;
		}
	} else {
		printlog("No plain message found for ArticleID $ArticleID.");
	}
}

sub usage {
	print "\notrs.TicketExport2Mbox.pl - export non autoqueued as junk messages to mbox format.\n\n" .
		"Usage:\n\n" .
		"$0 [options] [TicketNumber] [TicketID]\n\n" .
		"  ~OR~\n\n" .
		"$0 [options] --TicketId no1 no2 no3\n\n" .
		"  ~OR~\n\n" .
		"$0 [options] --TicketNumber no1 no2 no3\n\n" .
		"Valid Options are:\n" .
		"  --help                          display this option help\n" .
		"  --mbox /path/to/mbox            mbox output file (default $Mbox)\n" .
		"  --close                         change ticket status to 'closed successful'\n" .
		"  --rebuild                       run all messages for Bayes rebuild (don't skip already closed messages)\n" .
		"  --TicketID no1 no2 no3          export messages by TicketID\n" .
		"  --TicketNumber no1 no2 no3      export messages by TicketNumber\n\n";
    exit;
}

# otrs messes with multiline headers, undo that
sub cleanupArticle {
	my $msg;
	my $position = 'head';
	for my $line (split /^/, shift) {
		if ($line =~ /^$/) {
			$position = 'body';
		} elsif ($position eq 'head') {
			$line =~ s/(\t+)/\n$1/g;
		}
		$msg .= $line;
	}
	return $msg;
}

sub OTRSLog {
    my $msg = $_[0] ? $_[0] : '';
    my $priority = $_[1] ? $_[1] : 'notice';
	$CommonObject{LogObject}->Log(
		Priority => $priority,
		Message  => $msg,
	);
}

sub printlog {
	my $msg = $_[0] ? $_[0] : '';
	my $severity = $_[1] ? $_[1] : 'notice'; # notice warning error etc.
	Sys::Syslog::setlogsock('unix');
	Sys::Syslog::openlog($ident,'ndelay,pid','user');
	Sys::Syslog::syslog($severity,$msg);
	Sys::Syslog::closelog();
}
