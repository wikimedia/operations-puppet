#!/usr/bin/perl
# ---------------------------------------------------- #
# File : check_linux_stats
# Author : Damien SIAUD
# Date : 07/12/2009
# Rev. Date : 07/05/2010
# ---------------------------------------------------- #
# This script require Sys::Statistics::Linux
#
# Plugin check for nagios 
#
# License Information:
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>. 
#
# ---------------------------------------------------- # 

use lib "/usr/local/nagios/libexec";
use utils qw($TIMEOUT %ERRORS &print_revision &support);
use Getopt::Long;
use Sys::Statistics::Linux;
use Sys::Statistics::Linux::Processes;
use Data::Dumper;

use vars qw($script_name $script_version $o_sleep $o_pattern $o_cpu $o_procs $o_process $o_mem $o_net $o_disk $o_io $o_load $o_file $o_socket $o_paging $o_help $o_version $o_warning $o_critical $o_unit);
use strict;

# --------------------------- globals -------------------------- #

$script_name = "check_linux_stats";
$script_version = "1.2";
$o_help = undef;
$o_pattern = undef;
$o_version = undef;
$o_warning = 70;
$o_critical = 90;
$o_sleep = 1;
$o_unit = "MB";
my $status = 'UNKNOWN';

# ---------------------------- main ----------------------------- #
check_options();

if($o_cpu){
	check_cpu();
}
elsif($o_mem){
	check_mem();
}
elsif($o_disk){
	check_disk();
}
elsif($o_io){
        check_io();
}
elsif($o_net){
        check_net();
}
elsif($o_load){
        check_load();
}
elsif($o_file){
        check_file();
}
elsif($o_procs){
        check_procs();
}
elsif($o_socket){
        check_socket();
}
elsif($o_process){
        check_process();
}
elsif($o_paging){
        check_paging();
}

exit $ERRORS{$status};


sub check_cpu {
	my $lxs = Sys::Statistics::Linux->new(cpustats  => 1);
	$lxs->init;
	sleep $o_sleep;
	my $stat = $lxs->get;

	if(defined($stat->cpustats)) {
		$status = "OK";
		my $cpu  = $stat->cpustats->{cpu};
		my $cpu_used=sprintf("%.2f", (100-$cpu->{idle}));

		if ($cpu_used >= $o_critical) {
        		$status = "CRITICAL";
		}
		elsif ($cpu_used >= $o_warning) {
        		$status = "WARNING";
		}
		print "CPU $status : idle $cpu->{idle}% | user=$cpu->{user}% system=$cpu->{system}% iowait=$cpu->{iowait}% idle=$cpu->{idle}%;$o_warning;$o_critical";
	}
	else {
                print "No data";
        }
}

sub check_procs {
   	my $lxs = Sys::Statistics::Linux->new(procstats => 1);
	$lxs->init;
        sleep $o_sleep;
        my $stat = $lxs->get;

        if(defined($stat->procstats)) {
		$status = "OK";
		my $procs = $stat->procstats;
		
		if($procs->{count} >= $o_critical) {
                        $status = "CRITICAL";
                }
                elsif ($procs->{count} >= $o_warning) {
                        $status = "WARNING";
                }
                print "PROCS $status : count $procs->{count} |count=$procs->{count};$o_warning;$o_critical runqueue=$procs->{runqueue} blocked=$procs->{blocked} running=$procs->{running} new=$procs->{new}";

	}
}


sub check_process {
	my $return_str = "";
        my $perfdata = "";
	# pidfiles
        my @pids = ();
        for my $file (split(/,/, $o_pattern)) {
                open FILE, $file or die "Could not read from $file, program halting.";
                # read the record, and chomp off the newline
                chomp(my $pid = <FILE>);
                close FILE;
                if($pid=~/^\d+$/){
                        push @pids,$pid;
		}
        }
        
        if($#pids>-1) {
		 my $lxs = Sys::Statistics::Linux::Processes->new(pids => \@pids);
        	$lxs->init;
        	sleep $o_sleep;
        	my $processes = $lxs->get;
		my @pname = ();

        	if(defined($processes)) {
                	$status = "OK";

			my $crit = 0; #critical counter
                	my $warn = 0; #warning counter
                	foreach my $process (keys (%$processes)) {
                        	my $vsize = $processes->{$process}->{vsize};
                        	my $nswap = $processes->{$process}->{nswap};
                        	my $cnswap = $processes->{$process}->{cnswap};
                        	my $cpu = $processes->{$process}->{cpu};
                    		my $cmd = $processes->{$process}->{cmd};
				$cmd =~s/\W+//g;

	                        if($vsize >= $o_critical) {$crit++; push @pname,$cmd;}
                                elsif($vsize >= $o_warning){ $warn++; push @pname,$cmd;}

                                $perfdata .= " ".$cmd."_vsize=$vsize;$o_warning;$o_critical ".$cmd."_nswap=$nswap ".$cmd."_cnswap=$cnswap ".$cmd."_cpu=$cpu";
                        }
		
			if($crit>0) {$status="CRITICAL";}
			elsif($warn>0) {$status="WARNING";}
		
                }
                print "PROCESSES $status : ".join(',',@pname)." |$perfdata";
	}
}

sub check_socket {
        my $lxs = Sys::Statistics::Linux->new(sockstats => 1);
	$lxs->init;
        sleep $o_sleep;
        my $stat = $lxs->get;

        if(defined($stat->sockstats)) {
		$status = "OK";
		my $socks = $stat->sockstats;
		
		if($socks->{used} >= $o_critical) {
                        $status = "CRITICAL";
                }
                elsif($socks->{used} >= $o_warning) {
                        $status = "WARNING";
                }
		print "SOCKET USAGE  $status : used $socks->{used} |used=$socks->{used};$o_warning;$o_critical tcp=$socks->{tcp} udp=$socks->{udp} raw=$socks->{raw}";
	}
	else {
                print "No data";
        }
}

sub check_file {
        my $lxs = Sys::Statistics::Linux->new(filestats => 1);
	$lxs->init;
        sleep $o_sleep;
        my $stat = $lxs->get;

        if(defined($stat->filestats)) {
		$status = "OK";
		my $file = $stat->filestats;
		
		my ($fh_crit,$inode_crit) = split(/,/,$o_critical);
                my ($fh_warn,$inode_warn) = split(/,/,$o_warning);

		if(($file->{fhalloc}>=$fh_crit)||($file->{inalloc}>=$inode_crit)) {
                        $status = "CRITICAL";
                }
		elsif(($file->{fhalloc}>=$fh_warn)||($file->{inalloc}>=$inode_warn)) {
                        $status = "WARNING";
                }
		print "OPEN FILES $status allocated: $file->{fhalloc} (inodes: $file->{inalloc}) | fhalloc=$file->{fhalloc};$fh_warn;$fh_crit;$file->{fhmax} inalloc=$file->{inalloc};$inode_warn;$inode_crit;$file->{inmax} dentries=$file->{dentries}";
	}
	else {
                print "No data";
        }
}

sub check_mem {
        my $lxs = Sys::Statistics::Linux->new(memstats  => 1);
		$lxs->init;
        sleep $o_sleep;
        my $stat = $lxs->get;

	if(defined($stat->memstats)) {
                $status = "OK";
		
		my ($mem_crit,$swap_crit) = split(/,/,$o_critical);
		my ($mem_warn,$swap_warn) = split(/,/,$o_warning);
		
		my $mem = $stat->memstats;
		my $memused = sprintf("%.2f", ($mem->{memused}/$mem->{memtotal})*100);
		my $memcached = sprintf("%.2f", ($mem->{cached}/$mem->{memtotal})*100);
		my $swapused = sprintf("%.2f", ($mem->{swapused}/$mem->{swaptotal})*100);
		my $swapcached = sprintf("%.2f", ($mem->{swapcached}/$mem->{swaptotal})*100);
		my $active = sprintf("%.2f", ($mem->{active}/$mem->{memtotal})*100);
		
		if(($memused>=$mem_crit)||($swapused>=$swap_crit)) {
                        $status = "CRITICAL";
                }
                elsif (($memused>=$mem_warn)||($swapused>=$swap_warn)) {
                        $status = "WARNING";
                }
	
			print "MEMORY $status : Mem used: $memused%, Swap used: $swapused% |MemUsed=$memused%;$mem_warn;$mem_crit SwapUsed=$swapused;$swap_warn;$swap_crit MemCached=$memcached SwapCached=$swapcached Active=$active";
        }
	else {
		print "No data";
	}
}

sub check_disk {
	my $lxs = Sys::Statistics::Linux->new(diskusage => 1);
	$lxs->init;
        sleep $o_sleep;
        my $stat = $lxs->get;
	my $return_str = "";
	my $perfdata = "";

        if(defined($stat->diskusage)) {
                $status = "OK";

                my $disk = $stat->diskusage;
		if(!defined($o_pattern)){ $o_pattern = 'all';}
		
		my $checkthis;
		map {$checkthis->{$_}++} split(/,/, $o_pattern);
		
		my $crit = 0; #critical counter
		my $warn = 0; #warning counter
		foreach my $device (keys (%$disk)) {
			my $usage = $disk->{$device}->{usage};   # KB
			my $free = $disk->{$device}->{free};     # KB
			my $total = $disk->{$device}->{total};   # KB
			my $mountpoint = $disk->{$device}->{mountpoint};
			my $percentused = sprintf("%.2f", ($usage/$total)*100);
                        my $percentfree = sprintf("%.2f", ($free/$total)*100);
			my $MBused = sprintf("%.2f", ($usage/1024));
                        my $MBfree = sprintf("%.2f", ($free/1024));
                        my $MBtotal = sprintf("%.2f", ($total/1024));
			my $GBused = sprintf("%.2f", ($MBused/1024));
                        my $GBfree = sprintf("%.2f", ($MBfree/1024));
                        my $GBtotal = sprintf("%.2f", ($MBtotal/1024));

			if(defined($checkthis->{$mountpoint})||defined($checkthis->{all})){
				if($o_unit =~ /\%/) {
					if($percentfree<=$o_critical){ $crit++;}
					elsif($percentfree<=$o_warning){ $warn++;}
					$return_str .= " ".$mountpoint." ".$usage."KB on ".$total."KB ($percentfree% free)";
	                                $perfdata .= " ".$mountpoint."=".$usage."KB";
				}
				elsif($o_unit =~ /KB/i) {
                                        if($free<=$o_warning){ $warn++;}
					elsif($free<=$o_critical){ $crit++;}
					$return_str .= " ".$mountpoint." ".$usage."KB on ".$total."KB ($percentfree% free)";
					$perfdata .= " ".$mountpoint."=".$usage."KB";
				}
				elsif($o_unit =~ /MB/i) {
                                        if($MBfree<=$o_warning){ $warn++;}
                                        elsif($MBfree<=$o_critical){ $crit++;}
                                        $return_str .= " ".$mountpoint." ".$MBused."MB on ".$MBtotal."MB ($percentfree% free)";
                                        $perfdata .= " ".$mountpoint."=".$MBused."MB";
                                }
				elsif($o_unit =~ /GB/i) {
                                        if($GBfree<=$o_warning){ $warn++;}
                                        elsif($GBfree<=$o_critical){ $crit++;}
                                        $return_str .= " ".$mountpoint." ".$GBused."GB on ".$GBtotal."GB ($percentfree% free)";
                                        $perfdata .= " ".$mountpoint."=".$GBused."GB";
                                }
			}
		}

		if($crit>0) {$status="CRITICAL";}
		elsif($warn>0) {$status="WARNING";}
        }
	print "DISK $status used : $return_str|$perfdata";
}


sub check_io {
	my $lxs = Sys::Statistics::Linux->new(diskstats => 1);
	$lxs->init;
        sleep $o_sleep;
        my $stat = $lxs->get;
	my $return_str = "io :";
        my $perfdata = "";

        if(defined($stat->diskstats)) {
                $status = "OK";

                my $disk = $stat->diskstats;
		if(!defined($o_pattern)){ $o_pattern = 'all';}

                my $checkthis;
                map {$checkthis->{$_}++} split(/,/, $o_pattern);

		my ($read_crit,$write_crit) = split(/,/,$o_critical);
                my ($read_warn,$write_warn) = split(/,/,$o_warning);

                my $crit = 0; #critical counter
                my $warn = 0; #warning counter
		foreach my $device (keys (%$disk)) {
			my $rdreq = $disk->{$device}->{rdreq};
			my $wrtreq = $disk->{$device}->{wrtreq};
			my $ttreq = $disk->{$device}->{ttreq};
			my $rdbyt = $disk->{$device}->{rdbyt};
                        my $wrtbyt = $disk->{$device}->{wrtbyt};
                        my $ttbyt = $disk->{$device}->{ttbyt};
			
			if($o_unit =~ /BYTES/i) {
				if(defined($checkthis->{$device})||defined($checkthis->{all})){
                                        if(($rdbyt>=$read_crit)||($wrtbyt>=$write_crit)){ $crit++;}
                                        elsif(($rdbyt>=$read_warn)||($wrtbyt>=$write_warn)){ $warn++;}

                                        $perfdata .= " ".$device."_read=$rdbyt;$read_warn;$read_crit ".$device."_write=$wrtbyt;$write_warn;$write_crit";
                                }
			}
			else {
                        	if(defined($checkthis->{$device})||defined($checkthis->{all})){
                                	if(($rdreq>=$read_crit)||($wrtreq>=$write_crit)){ $crit++;}
                                	elsif(($rdreq>=$read_warn)||($wrtreq>=$write_warn)){ $warn++;}
				
                                	$perfdata .= " ".$device."_read=$rdreq;$read_warn;$read_crit ".$device."_write=$wrtreq;$write_warn;$write_crit";
				}
                        }
                }
		if($crit>0) {$status="CRITICAL";}
		elsif($warn>0) {$status="WARNING";}
		
		print "DISK $status $return_str |$perfdata";	
        }
}

sub check_net {
	my $lxs = Sys::Statistics::Linux->new(netstats => 1);
	$lxs->init;
        sleep $o_sleep;
        my $stat = $lxs->get;

	my $return_str = "";
        my $perfdata = ""; 
        if(defined($stat->netstats)) {
                $status = "OK";
                my $net = $stat->netstats;
		if(!defined($o_pattern)){ $o_pattern = 'all';}

                my $checkthis;
                map {$checkthis->{$_}++} split(/,/, $o_pattern);

		my $crit = 0; #critical counter
                my $warn = 0; #warning counter
                foreach my $device (keys (%$net)) {
			my $txbyt = $net->{$device}->{txbyt};
			my $rxerrs = $net->{$device}->{rxerrs};
			my $ttbyt = $net->{$device}->{ttbyt};
			my $txerrs = $net->{$device}->{txerrs};
			my $txdrop = $net->{$device}->{txdrop};
			my $txcolls = $net->{$device}->{txcolls};
			my $rxbyt = $net->{$device}->{rxbyt};
			my $rxdrop = $net->{$device}->{rxdrop};

			 if(defined($checkthis->{$device})||defined($checkthis->{all})){
                                if($ttbyt>=$o_critical){ $crit++;}
                                elsif($ttbyt>=$o_warning){ $warn++;}

				$return_str .= $device.":".$ttbyt."KB ";
                                $perfdata .= " ".$device."_txbyt=".$txbyt."KB ".$device."_txerrs=".$txerrs."KB ".$device."_rxbyt=".$rxbyt."KB ".$device."_rxerrs=".$rxerrs."KB";
                        }
		}

		if($crit>0) {$status="CRITICAL";}
		elsif($warn>0) {$status="WARNING";}
		print "NET USAGE $status $return_str |$perfdata";
        }
}

sub check_load {
	my $lxs = Sys::Statistics::Linux->new(loadavg => 1);
	$lxs->init;
        sleep $o_sleep;
        my $stat = $lxs->get;

        if(defined($stat->loadavg)) {
                $status = "OK";
                my $load = $stat->loadavg;
		my ($warn_1,$warn_5,$warn_15) = split(/,/,$o_warning);
		my ($crit_1,$crit_5,$crit_15) = split(/,/,$o_critical);

		if(($load->{avg_1}>=$crit_1)||($load->{avg_5}>=$crit_5)||($load->{avg_15}>=$crit_15)) {
			 $status = "CRITICAL";			
		}
		elsif(($load->{avg_1}>=$warn_1)||($load->{avg_5}>=$warn_5)||($load->{avg_15}>=$warn_15)) {
                        $status = "WARNING";
		}
                print "LOAD AVERAGE $status : $load->{avg_1},$load->{avg_5},$load->{avg_15} | load1=$load->{avg_1};$warn_1;$crit_1;0 load5=$load->{avg_5};$warn_5;$crit_5;0 load15=$load->{avg_15};$warn_15;$crit_15;0";

        }
	else {
		print "No data";
	}
}

sub check_paging {
	my $lxs = Sys::Statistics::Linux->new(pgswstats => 1);
    	$lxs->init;
	sleep $o_sleep;
        my $stat = $lxs->get;
	if(defined($stat->pgswstats)) {
                $status = "OK";
                my $page = $stat->pgswstats;
		my ($warn_in,$warn_out) = split(/,/,$o_warning);
                my ($crit_in,$crit_out) = split(/,/,$o_critical);
		if(($page->{pgpgin}>=$crit_in)||($page->{pgpgout}>=$crit_out)) {
                         $status = "CRITICAL";
                }
		elsif(($page->{pgpgin}>=$warn_in)||($page->{pgpgout}>=$warn_out)) {
                        $status = "WARNING";
                }
                print "Paging $status : In:$page->{pgpgin}, Out:$page->{pgpgout} | pgpgin=$page->{pgpgin};$warn_in;$crit_in;0 pgpgout=$page->{pgpgout};$warn_out;$crit_out;0 pswpin=$page->{pswpin} pswpout=$page->{pswpout}";
	}
	else {
                print "No data";
        }
}


sub usage {
	print "Usage: $0 -C|-P|-M|-N|-D|-I|-L|-F|-S|-w -p <pattern> -w <warning> -c <critical> [-s <sleep>] [-u <unit>] [-V] [-h]\n";
}


sub version {
	print "$script_name v$script_version\n";
}


sub help {
	version();
	usage();

	print <<HELP;
	-h, --help
   		print this help message
	-C, --cpu=CPU USAGE
	-P, --procs
	-M, --memory=MEMORY USAGE
	-N, --network=NETWORK USAGE
	-D, --disk=DISK USAGE
	-I, --io=DISK IO USAGE
	-L, --load=LOAD AVERAGE
	-F, --file=FILE STATS
	-S, --socket=SOCKET STATS
	-W, --paging=PAGING AND SWAPPING STATS
	-p, --pattern
		eth0,eth1...sda1,sda2.../usr,/tmp
	-w, --warning
	-c, --critical
	-s, --sleep
	-u, --unit
               %, KB, MB or GB left on disk usage, default : MB	
	       REQS OR BYTES on disk io statistics, default : REQS
	-V, --version
		version number

	ex : 
	Memory usage                    : perl check_linux_stats.pl -M -w 90 -c 95
	Cpu usage                       : perl check_linux_stats.pl -C -w 90 -c 95 -s 5
	Disk usage                      : perl check_linux_stats.pl -D -w 95 -c 100 -u % -p /tmp,/usr,/var
	Load average                    : perl check_linux_stats.pl -L -w 10,8,5 -c 20,18,15
	Paging statistics				: perl check_linux_stats.pl -W -w 10,1000 -c 20,2000 -s 3
	Process statistics              : perl check_linux_stats.pl -P -w 100 -c 200
	I/O statistics on disk device   : perl check_linux_stats.pl -I -w 95 -c 100 -p sda1,sda4,sda5,sda6      
	Network usage                   : perl check_linux_stats.pl -N -w 10000 -c 100000000 -p eth0
	Processes virtual memory        : perl check_linux_stats.pl -T -w 9551820 -c 9551890 -p /var/run/sendmail.pid 
HELP
}



sub check_options {
	Getopt::Long::Configure("bundling");
	GetOptions(
		'h'	=> \$o_help,		'help'		=> \$o_help,
		's:i'	=> \$o_sleep,		'sleep:i'	=> \$o_sleep,
		'C'	=> \$o_cpu,		'cpu'		=> \$o_cpu,
		'P'	=> \$o_procs, 		'procs'		=> \$o_procs,
		'T'	=> \$o_process, 	'top'		=> \$o_process,
		'M'	=> \$o_mem,		'memory'	=> \$o_mem,
		'N'	=> \$o_net,		'network'	=> \$o_net,
		'D'	=> \$o_disk,		'disk'		=> \$o_disk,
		'I'	=> \$o_io,		'io'		=> \$o_io,	
		'L'	=> \$o_load,		'load'		=> \$o_load,
		'F'	=> \$o_file,		'file'		=> \$o_file,
		'S'	=> \$o_socket,		'socket'	=> \$o_socket,
		'W'	=> \$o_paging,		'paging'	=> \$o_paging,
		'V'	=> \$o_version,		'version'	=> \$o_version,
		'p:s'	=> \$o_pattern,		'pattern:s'	=> \$o_pattern,
		'w:s'	=> \$o_warning,		'warning:s'	=> \$o_warning,
		'c:s'	=> \$o_critical,	'critical:s'	=> \$o_critical,
		'u:s'	=> \$o_unit,	        'unit:s'	=> \$o_unit
	);

	if(defined($o_help)) {
		help(); 
		exit $ERRORS{'UNKNOWN'};
	}

	if(defined($o_version)) {
		version();
		exit $ERRORS{'UNKNOWN'};
	}
}

