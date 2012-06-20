# ganglia.pp
#
# Parameters:
#  - $deaf:			Is the gmond process an aggregator
#  - $cname:			Cluster / Cloud 's name
#  - $location:			Machine's location
#  - $mcast_address:		Multicast "cluster" to join and send data on (production only)
#  - $gmetad_host:		Hostname or IP of gmetad server used by gmond (labs only)
#  - $authority_url:		URL used by gmond and gmetad
#  - $gridname:			Grid name used by gmetad
#  - $data_sources:		Hash of datasources used by gmetad (production only)
#  - $rra_sizes:		Round-robin archives sizes used by gmetad
#  - $rrd_rootdir:		Directory to store round-robin dbs used by gmetad
#  - $gmetad_conf:		gmetad conf filename (ends in '.labsstub' for labs)
#  - $ganglia_servername:	Server name used by apache
#  - $ganglia_serveralias:	Server alias(es) used by apache
#  - $ganglia_webdir:		Path of web directory used by apache


class ganglia {

	if $hostname in $decommissioned_servers {
		$cluster = "decommissioned"
		$deaf = "no"
	} else {
		if ! $cluster {
			$cluster = "misc"
		}
		if $ganglia_aggregator {
			$deaf = "no"
		} else {
			$deaf = "yes"
		}
	}

	if $realm == "labs" {
		$authority_url = "http://ganglia.wmflabs.org"
		$gmetad_host = "10.4.0.79"
	} else {
		$authority_url = "http://ganglia.wikimedia.org"
	}

	$location = "unspecified"

	$ip_prefix = $site ? {
		"pmtpa"	=> "239.192.0",
		"eqiad"	=> "239.192.1",
		"esams"	=> "239.192.20",
	}

	$name_suffix = " ${site}"

	# NOTE: Do *not* add new clusters *per site* anymore,
	# the site name will automatically be appended now,
	# and a different IP prefix will be used.
	$ganglia_clusters = {
		"decommissioned" => {
			"name"		=> "Decommissioned servers",
			"ip_oct"	=> "1" },
		"appserver"	=>	{
			"name"		=> "Application servers",
			"ip_oct"	=> "11"	},
		"imagescaler"	=>	{
			"name"		=> "Image scalers",
			"ip_oct"	=> "12" },
		"api_appserver"	=>	{
			"name"		=> "API application servers",
			"ip_oct"	=> "13" },
		"misc"		=>	{
			"name"		=> "Miscellaneous",
			"ip_oct"	=> "8" },
		"mysql"		=>	{
			"name"		=> "MySQL",
			"ip_oct"	=> "5" },
		"pdf"		=>	{
			"name"		=> "PDF servers",
			"ip_oct"	=> "15" },
		"search"	=>	{
			"name"		=> "Search",
			"ip_oct"	=> "4" },
		"squids_text"	=>	{
			"name"		=> "Text squids",
			"ip_oct"	=> "7" },
		"squids_upload"	=>	{
			"name"		=> "Upload squids",
			"ip_oct"	=> "6" },
		"cache_text"	=> {
			"name"		=> "Text caches",
			"ip_oct"	=> "20" },
		"cache_bits"	=> {
			"name"		=> "Bits caches",
			"ip_oct"	=> "21" },
		"cache_upload"	=> {
			"name"		=> "Upload caches",
			"ip_oct"	=> "22" },
		"payments"	=> {
			"name"		=> "Fundraiser payments",
			"ip_oct"	=> "23" },
		"bits_appserver"	=> {
			"name"		=> "Bits application servers",
			"ip_oct"	=> "24" },
		"squids_api"		=> {
			"name"		=> "API squids",
			"ip_oct"	=> "25" },
		"ssl"		=> {
			"name"		=> "SSL cluster",
			"ip_oct"	=> "26" },
		"swift" => {
			"name"		=> "Swift",
			"ip_oct"	=> "27" },
		"cache_mobile"	=> {
			"name"		=> "Mobile caches",
			"ip_oct"	=> "28" },
		"virt"	=> {
			"name"		=> "Virtualization cluster",
			"ip_oct"	=> "29" },
		"gluster"	=> {
			"name"		=> "Glusterfs cluster",
			"ip_oct"	=> "30" },
	}
	# NOTE: Do *not* add new clusters *per site* anymore,
	# the site name will automatically be appended now,
	# and a different IP prefix will be used.

	# gmond.conf template variables
	if $realm == "labs" {
		$cname = $instanceproject
	}
	else {
		$ipoct = $ganglia_clusters[$cluster]["ip_oct"]
		$mcast_address = "${ip_prefix}.${ipoct}"
		$clustername = $ganglia_clusters[$cluster][name]
		$cname = "${clustername}${name_suffix}"
	}

	if versioncmp($lsbdistrelease, "9.10") >= 0 {
		$gmond = "ganglia-monitor"
	}
	else {
		$gmond = "gmond"
	}

	$gmondpath = $gmond ? {
		"ganglia-monitor"       => "/etc/ganglia/gmond.conf",
		default                 => "/etc/gmond.conf"
	}


	# Resource definitions
	file { "gmondconfig":
		require => Package[$gmond],
		name	=> $gmondpath,
		owner	=> "root",
		group	=> "root",
		mode	=> 0444,
		content => template("ganglia/gmond_template.erb"),
		notify  => Service[gmond],
		ensure	=> present
	}

	case $gmond {
		gmond: {
			package {
				"gmond":
					ensure => latest,
					alias => "gmond-package";
				"ganglia-monitor":
					before => Package[gmond],
					ensure => purged;
			}
		}
		ganglia-monitor: {
			package {
				"gmond":
					before => Package[ganglia-monitor],
					ensure => purged;
				"ganglia-monitor":
					ensure => latest,
					alias => "gmond-package";
			}

	                file { [ "/etc/ganglia/conf.d", "/usr/lib/ganglia/python_modules" ]:
				require => Package[ganglia-monitor],
				ensure => directory;
			}

			file { "/etc/gmond.conf":
				ensure => absent;
			}
		}
	}

	service {
		"gmond":
			name		=> $gmond,
			require		=> [ File[gmondconfig], Package["gmond-package"] ],
			subscribe	=> File[gmondconfig],
			hasstatus	=> false,
			pattern		=> "gmond",
			ensure		=> running;
	}

	systemuser { gmetric: name => "gmetric", home => "/home/gmetric", shell => "/bin/sh" }

	# Class for setting up the collector (gmetad)
	class collector {
		system_role { "ganglia::collector": description => "Ganglia gmetad aggregator" }

		package { "gmetad":
			ensure => latest;
		}

		if $realm == "labs" {
			$gridname = "wmflabs"
			# for labs, just generate a stub gmetad configuration without data_source lines
			$gmetad_conf = "gmetad.conf.labsstub"
			$authority_url = "http://ganglia.wmflabs.org"
			$rra_sizes = '"RRA:AVERAGE:0.5:1:360" "RRA:AVERAGE:0.5:24:245" "RRA:AVERAGE:0.5:168:241" "RRA:AVERAGE:0.5:672:241" "RRA:AVERAGE:0.5:5760:371"'
			$rrd_rootdir = "/mnt/ganglia_tmp/rrds.pmtpa"
		} else {
			$gridname = "Wikimedia"
			$gmetad_conf = "gmetad.conf"
			$authority_url = "http://ganglia.wikimedia.org"
			case $hostname {
				# manutius runs gmetad to get varnish data into torrus
				/^manutius$/: {
					$data_sources = {
						"Upload caches eqiad" => "cp1021.eqiad.wmnet cp1022.eqiad.wmnet"
					}
					$rra_sizes = '"RRA:AVERAGE:0:1:4032" "RRA:AVERAGE:0.17:6:2016" "RRA:MAX:0.17:6:2016" "RRA:AVERAGE:0.042:288:732" "RRA:MAX:0.042:288:732"'
				}
				default: {
					$data_sources = {
						"Decommissioned servers pmtpa" => "eiximenis.wikimedia.org",
						"Tesla" => "10 208.80.152.247",
						"Image scalers" => "srv100.pmtpa.wmnet srv219.pmtpa.wmnet",
						"API application servers" => "srv254.pmtpa.wmnet srv255.pmtpa.wmnet",
						"Application servers" => "srv258.pmtpa.wmnet srv259.pmtpa.wmnet",
						"Search pmtpa" => "search13.pmtpa.wmnet search14.pmtpa.wmnet",
						"MySQL" => "db50.pmtpa.wmnet db51.pmtpa.wmnet",
						"PDF servers" => "pdf1.wikimedia.org pdf2.wikimedia.org",
						"Upload squids" => "sq41.wikimedia.org sq42.wikimedia.org",
						"API squids" => "sq31.wikimedia.org sq35.wikimedia.org",
						"Miscellaneous" => "spence.wikimedia.org",
						"Text squids" => "sq59.wikimedia.org sq60.wikimedia.org",
						"Bits caches" => "sq67.wikimedia.org sq68.wikimedia.org",
						"Fundraiser payments" => "payments1.wikimedia.org payments2.wikimedia.org",
						"Bits application servers" => "srv191.pmtpa.wmnet srv192.pmtpa.wmnet",
						"SSL cluster" => "ssl1.wikimedia.org ssl2.wikimedia.org",
						"SSL cluster esams" => "ssl3001.esams.wikimedia.org ssl3002.esams.wikimedia.org",
						"Swift pmtpa" => "owa1.wikimedia.org owa2.wikimedia.org",
						"Virt pmtpa" => "virt2.pmtpa.wmnet virt3.pmtpa.wmnet",
						"Glusterfs cluster pmtpa" => "labstore1.pmtpa.wmnet labstore2.pmtpa.wmnet",
						"MySQL eqiad" => "db1017.eqiad.wmnet db1021.eqiad.wmnet",
						"Miscellaneous eqiad" => "carbon.wikimedia.org ms1004.eqiad.wmnet",
						"Mobile caches eqiad" => "cp1043.wikimedia.org cp1044.wikimedia.org",
						"Bits caches eqiad" => "arsenic.wikimedia.org niobium.wikimedia.org",
						"Upload caches eqiad" => "cp1021.eqiad.wmnet cp1022.eqiad.wmnet",
						"SSL cluster eqiad" => "ssl1001.wikimedia.org ssl1002.wikimedia.org",
						"Swift eqiad" => "copper.wikimedia.org zinc.wikimedia.org",
						"Text squids eqiad" => "cp1001.eqiad.wmnet cp1002.eqiad.wmnet",
						"Search eqiad" => "search1001.eqiad.wmnet search1002.eqiad.wmnet",
						"Decommissioned servers esams" => "knsq1.esams.wikimedia.org",
						"Bits caches esams" => "cp3001.esams.wikimedia.org cp3002.esams.wikimedia.org",
						"Text squids esams" => "amssq31.esams.wikimedia.org amssq32.esams.wikimedia.org",
						"Upload squids esams" => "knsq16.esams.wikimedia.org knsq17.esams.wikimedia.org",
						"Miscellaneous esams" => "hooft.esams.wikimedia.org"
					}
					$rra_sizes = '"RRA:AVERAGE:0.5:1:360" "RRA:AVERAGE:0.5:24:245" "RRA:AVERAGE:0.5:168:241" "RRA:AVERAGE:0.5:672:241" "RRA:AVERAGE:0.5:5760:371"'
					$rrd_rootdir = "/mnt/ganglia_tmp/rrds.pmtpa"
				}
			}
		}

		file { "/etc/ganglia/${gmetad_conf}":
			require => Package[gmetad],
			content => template("ganglia/gmetad.conf.erb"),
			mode => 0444,
			ensure	=> present
		}

		# for labs, gmond.conf and gmetad.conf are generated by a cron job
		if $realm == "labs" {
			file { "/etc/ganglia/gmond.conf.labsstub":
				source => "puppet:///files/ganglia/gmond.conf.labsstub",
				mode => 0444,
				ensure => present;
			}

			file { "/usr/local/sbin/generate-ganglia-conf.py":
				source => "puppet:///files/ganglia/generate-ganglia-conf.py",
				mode => 0755,
				ensure => present;
			}

			cron { generate-ganglia-conf:
				command => "/usr/local/sbin/generate-ganglia-conf.py",
				require => Package[gmetad],
				user => root,
				hour => [0, 4, 8, 12, 16, 20],
				minute => 30,
				ensure => present;
			}

			# log gmetad messages to /var/log/ganglia.log 
			file { "/etc/rsyslog.d/30-ganglia.conf":
				source => "puppet:///files/ganglia/rsyslog.d/30-ganglia.conf",
				mode => 0444,
				ensure => present,
				notify => Service["rsyslog"];
			}

			file { "/etc/logrotate.d/ganglia":
				source => "puppet:///files/logrotate/ganglia",
				mode => 0444,
				ensure => present;
			}
		}

		service { "gmetad":
			require => File["/etc/ganglia/${gmetad_conf}"],
			subscribe => File["/etc/ganglia/${gmetad_conf}"],
			hasstatus => false,
			ensure => running;
		}
	}

	# Class: ganglia::aggregator
	# for the machine class which listens on multicast and
	# collects all the ganglia information from other sources
	class aggregator {
		# This overrides the default ganglia-monitor script
		# with one that starts up multiple instances of gmond
		file { "/etc/init.d/ganglia-monitor":
			source => "puppet:///files/ganglia/ganglia-monitor",
			mode   => 0555,
			ensure => present
		}
	}
}

class ganglia::web {
# Class for the ganglia frontend machine

	require ganglia::collector,
		webserver::php5-gd,
		webserver::php5-mysql,
		svn::client

	class {'webserver::php5': ssl => 'true'; }

	file {
		"/etc/apache2/sites-available/ganglia.wikimedia.org":
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/apache/sites/ganglia.wikimedia.org",
			ensure => present;
		"/usr/local/bin/restore-gmetad-rrds":
			mode => 0555,
			owner => root,
			group => root,
			source => "puppet:///files/ganglia/restore-gmetad-rrds",
			ensure => present;
		"/usr/local/bin/save-gmetad-rrds":
			mode => 0555,
			owner => root,
			group => root,
			source => "puppet:///files/ganglia/save-gmetad-rrds",
			ensure => present;
		"/etc/init.d/gmetad":
			mode => 0555,
			owner => root,
			group => root,
			source => "puppet:///files/ganglia/gmetad",
			ensure => present;
		"/var/lib/ganglia/rrds.pmtpa/":
			ensure => directory;
		"/etc/rc.local":
			mode => 0555,
			owner => root,
			group => root,
			source => "puppet:///files/ganglia/rc.local",
			ensure => present;
	}

	apache_site { ganglia: name => "ganglia.wikimedia.org" }
	apache_module { rewrite: name => "rewrite" }

	package {
		"librrds-perl":
			before => Package[rrdtool],
			ensure => latest;
		"rrdtool":
			ensure => latest,
	}

	cron { "save-rrds":
		command => "/usr/local/bin/save-gmetad-rrds",
		user => root,
		minute => [ 7, 37 ],
		ensure => present
	}

	# Mount /mnt/ganglia_tmp as tmpfs to avoid Linux flushing mlocked
	# shm memory to disk
	mount { "/mnt/ganglia_tmp":
		device => "tmpfs",
		fstype => "tmpfs",
		options => "noatime,defaults,size=3000m",
		pass => 0,
		dump => 0,
		ensure => mounted;
	}
}

class ganglia::logtailer {
	# this class pulls in everything necessary to get a ganglia-logtailer instance on a machine

	package { "ganglia-logtailer":
		ensure => latest;
	}
}
