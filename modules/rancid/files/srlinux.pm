package srlinux;
# SPDX-License-Identifier: LicenseRef-Terrapin-Open-Source-License
# https://www.openhub.net/licenses/terrapin
##
## rancid 3.11
## Copyright (c) 2023 by Nick Peelman
## All rights reserved.
##
## This code is derived from software contributed to and maintained by
## Henry Kilmer, John Heasley, Andrew Partan,
## Pete Whiting, Austin Schutz, and Andrew Fort.
##
## Redistribution and use in source and binary forms, with or without
## modification, are permitted provided that the following conditions
## are met:
## 1. Redistributions of source code must retain the above copyright
##    notice, this list of conditions and the following disclaimer.
## 2. Redistributions in binary form must reproduce the above copyright
##    notice, this list of conditions and the following disclaimer in the
##    documentation and/or other materials provided with the distribution.
## 3. Neither the name of RANCID nor the names of its
##    contributors may be used to endorse or promote products derived from
##    this software without specific prior written permission.
##
## THIS SOFTWARE IS PROVIDED BY Nick Peelman AND CONTRIBUTORS
## ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
## TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
## PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COMPANY OR CONTRIBUTORS
## BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
## CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
## SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
## INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
## CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
## ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
## POSSIBILITY OF SUCH DAMAGE.
##
## It is the request of the authors, but not a condition of license, that
## parties packaging or redistributing RANCID NOT distribute altered versions
## of the etc/rancid.types.base file nor alter how this file is processed nor
## when in relation to etc/rancid.types.conf.  The goal of this is to help
## suppress our support costs.  If it becomes a problem, this could become a
## condition of license.
# 
#  The expect login scripts were based on Erik Sherk's gwtn, by permission.
# 
#  The original looking glass software was written by Ed Kern, provided by
#  permission and modified beyond recognition.
#
#  RANCID - Really Awesome New Cisco confIg Differ
#
#  srlinux.pm - Nokia SRLinux rancid procedures

use 5.010;
use strict 'vars';
use warnings;
no warnings 'uninitialized';
require(Exporter);
our @ISA = qw(Exporter);

use rancid 3.11;

our $proc;
our $memoryseen;

@ISA = qw(Exporter rancid main);
#XXX @Exporter::EXPORT = qw($VERSION @commandtable %commands @commands);

# load-time initialization
sub import {
    0;
}

# post-open(collection file) initialization
sub init {
    $proc = "";
    $memoryseen = 0;

    # add content lines and separators
    ProcessHistory("","","","#RANCID-CONTENT-TYPE: $devtype\n");

    0;
}

# main loop of input of device output
sub inloop {
    my($INPUT, $OUTPUT) = @_;
    my($cmd, $rval);

TOP: while(<$INPUT>) {
	tr/\015//d;
CMD:	if (/[#]\s?quit\s*$/) {
	    $clean_run = 1;
	    last;
	}
	if (/^Error:/ &&
	    !(/^Error: Invalid parameter\./ || /^Error: Bad command\./)) {
	    print STDOUT ("$host clogin error: $_");
	    print STDERR ("$host clogin error: $_") if ($debug);
	    $clean_run = 0;
	    last;
	}
	while (/[#]\s*($cmds_regexp)\s*$/) {
	    $cmd = $1;
	    if (!defined($prompt)) {
		print STDERR ("PROMPT LINE IS: $_\n") if ($debug);
		$prompt = ($_ =~ /(\w[:][\w.\@_()-:]+[#])\s?.*$/)[0];
		print STDERR ("PROMPT MATCH: $prompt\n") if ($debug);
	    }
	    print STDERR ("HIT COMMAND:$_") if ($debug);
	    if (! defined($commands{$cmd})) {
		print STDERR "$host: found unexpected command - \"$cmd\"\n";
		$clean_run = 0;
		last TOP;
	    }
	    if (! defined(&{$commands{$cmd}})) {
		printf(STDERR "$host: undefined function - \"%s\"\n",
		       $commands{$cmd});
		$clean_run = 0;
		last TOP;
	    }

	    $rval = &{$commands{$cmd}}($INPUT, $OUTPUT, $cmd);
	    delete($commands{$cmd});
	    if ($rval == -1) {
		$clean_run = 0;
		last TOP;
	    }
	    if (defined($prompt)) {
		if (/$prompt/) {
		    goto CMD;
		}
	    }
	}
    }
}

# This routine parses "file cat /var/log/srlinux/srl_boot.log"
sub CatBootLog {
    my($INPUT, $OUTPUT, $cmd) = @_;
    print STDERR "    In CatBootLog: $_" if ($debug);

    while (<$INPUT>) {
	tr/\015//d;
	last if (/^$prompt/);
	next if (/^(\s*|\s*$cmd\s*)$/);
	next if (/^\s+\^$/);
	return(-1) if (/error: invalid parameter/i);
	return(-1) if (/minor: cli command not allowed for this user/i);
        # if file doesn't exist, return 0
        return(0) if (/minor: cli could not access file/i);
    }
}

# This routine parses "show version" commands
sub ShowVersion {
    my($INPUT, $OUTPUT, $cmd) = @_;
    print STDERR "    In ShowVersion: $_" if ($debug);

    $_ =~ s/ +/ /;
    ProcessHistory("COMMENTS","keysort","C1","# $_");

    while (<$INPUT>) {
	tr/\015//d;
	last if (/^$prompt/);
	next if (/Memory/i); # Filter Total and Free Memory Lines
	next if (/^--\{\s*\+?\s*\w+\s*\}--\[\s+\]--$/); # Filter "--{ + running }--[  ]--"
	return(-1) if (/error: invalid parameter/i);
	return(-1) if (/minor: cli command not allowed for this user/i);

	ProcessHistory("COMMENTS","keysort","C1","# $_");
    }
}

# This routine parses "show platform" commands
sub ShowPlatform {
    my($INPUT, $OUTPUT, $cmd) = @_;
    print STDERR "    In ShowPlatform: $_" if ($debug);
    $_ =~ s/ +/ /;
    ProcessHistory("COMMENTS","keysort","C1","# $_");

    while (<$INPUT>) {
	tr/\015//d;
	last if (/^$prompt/);
	next if (/Temperature/i);
	next if (/Fan Speed/i);
	next if (/^--\{\s+\+?\s+\w+\s+\}--\[\s+\]--$/);
	return(-1) if (/error: invalid parameter/i);
	return(-1) if (/minor: cli command not allowed for this user/i);

	ProcessHistory("COMMENTS","keysort","C1","# $_");
    }
}

# This routine parses "info flat within the running context"
sub RunningConfig {
    my($INPUT, $OUTPUT, $cmd) = @_;
    print STDERR "    In RunningConfig: $_" if ($debug);
    ProcessHistory("","","","#\n# $_");
    my($linecnt) = 0;

    while (<$INPUT>) {
        tr/\015//d;
        $found_end = 1 if (/^$prompt/);
        last if (/^$prompt/);
        next if (/^--\{\s+\+?\s+\w+\s+\}--\[\s+\]--$/); 
        return(-1) if (/error: invalid parameter/i);
        return(-1) if (/minor: cli command not allowed for this user/i);

        s/echo \"(.*)\"/# $1/i;

        $linecnt++; 

        # password/community filtering - for info flat format
        if (/^(.*\s+community)\s+(\$\S+)/) {
            if ($filter_commstr) {
                ProcessHistory("SNMPSERVERCOMM","","", "#$1 <removed> $'") &&
                next;
            } else {
                ProcessHistory("SNMPSERVERCOMM","","","$_") && next;
            }
        }
        if (/^(.*\s+trap-target\s+.*)\s+(notify-community)\s+("\S+")/) { 
            if ($filter_commstr) {
                ProcessHistory("","","","#$1 $2 <removed>$'") && next;
            } else { 
                ProcessHistory("","","","$_") && next;
            }
        }
        if (/^(.*\s+password)\s+(\$\S+)/) {
            if ($filter_pwds >= 1) {
                ProcessHistory("","","","#$1 <removed>$'") && next;
            } else {
                ProcessHistory("","","","$_") && next;
            }
        }
        if (/^(.*\s+key)\s+(\$\S+)/) {
            if ($filter_pwds >= 1) { 
                ProcessHistory("","","","#$1 <removed>$'") && next;
            } else {
                ProcessHistory("","","","$_") && next;
            }
        }

        ProcessHistory("","","","$_");
    }

    return(0);
}

1;