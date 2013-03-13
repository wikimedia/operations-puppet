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

	if $::hostname in $::decommissioned_servers {
		$cluster = "decommissioned"
		$deaf = "no"
	} else {
		if ! $::cluster {
			$cluster = "misc"
		}
		# aggregator should not be deaf (they should listen)
		# ganglia_aggregator for production are defined in site.pp;
		# for labs, 'deaf = "no"' is defined in gmond.conf.labsstub
		if $ganglia_aggregator {
			$deaf = "no"
		} else {
			$deaf = "yes"
		}
	}

	if $::realm == "labs" {
		$authority_url = "http://ganglia.wmflabs.org"
		# labs does not use multicast so needs an explict gmetad_host
		$gmetad_host = "10.4.0.79"
	} else {
		$authority_url = "http://ganglia.wikimedia.org"
	}

	$location = "unspecified"

	$ip_prefix = $::site ? {
		"pmtpa"	=> "239.192.0",
		"eqiad"	=> "239.192.1",
		"esams"	=> "239.192.20",
	}

	$name_suffix = " ${::site}"

	# NOTE: Do *not* add new clusters *per site* anymore,
	# the site name will automatically be appended now,
	# and a different IP prefix will be used.
	$ganglia_clusters = {
		"decommissioned" => {
			"name"		=> "Decommissioned servers",
			"ip_oct"	=> "1" },
		"lvs" => {
			"name"		=> "LVS loadbalancers",
			"ip_oct"	=> "2" },
		"search"	=>	{
			"name"		=> "Search",
			"ip_oct"	=> "4" },
		"mysql"		=>	{
			"name"		=> "MySQL",
			"ip_oct"	=> "5" },
		"squids_upload"	=>	{
			"name"		=> "Upload squids",
			"ip_oct"	=> "6" },
		"squids_text"	=>	{
			"name"		=> "Text squids",
			"ip_oct"	=> "7" },
		"misc"		=>	{
			"name"		=> "Miscellaneous",
			"ip_oct"	=> "8" },
		"appserver"	=>	{
			"name"		=> "Application servers",
			"ip_oct"	=> "11"	},
		"imagescaler"	=>	{
			"name"		=> "Image scalers",
			"ip_oct"	=> "12" },
		"api_appserver"	=>	{
			"name"		=> "API application servers",
			"ip_oct"	=> "13" },
		"pdf"		=>	{
			"name"		=> "PDF servers",
			"ip_oct"	=> "15" },
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
		"jobrunner"	=>	{
			"name"		=> "Jobrunners",
			"ip_oct"	=> "31" },
		"analytics"		=> {
			"name"		=> "Analytics cluster",
			"ip_oct"	=> "32" },
		"memcached"		=> {
			"name"		=> "Memcached",
			"ip_oct"	=> "33" },
		"videoscaler"		=> {
			"name"		=> "Video scalers",
			"ip_oct"	=> "34" },
		"fundraising"	=> {
			"name"		=> "Fundraising",
			"ip_oct"	=> "35" },
		"ceph"			=> {
			"name"		=> "Ceph",
			"ip_oct"	=> "36" },
		"parsoid"		=> {
			"name"		=> "Parsoid",
			"ip_oct"	=> "37" },
		"parsoidcache"		=> {
			"name"		=> "Parsoid Varnish",
			"ip_oct"	=> "38" },
	}
	# NOTE: Do *not* add new clusters *per site* anymore,
	# the site name will automatically be appended now,
	# and a different IP prefix will be used.

	# gmond.conf template variables
	if $::realm == "labs" {
		# use project names for cluster names in labs
		$cname = $instanceproject
	}
	else {
		$ipoct = $ganglia_clusters[$cluster]["ip_oct"]
		$mcast_address = "${ip_prefix}.${ipoct}"
		$clustername = $ganglia_clusters[$cluster][name]
		$cname = "${clustername}${name_suffix}"
	}

	if versioncmp($::lsbdistrelease, "9.10") >= 0 {
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
			include ::ganglia::monitor::packages
			
			# package {
			# 	"gmond":
			# 		before => Package[ganglia-monitor],
			# 		ensure => purged;
			# 	"ganglia-monitor":
			# 		ensure => present,
			# 		alias => "gmond-package";
			# }

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
			ensure => present;
		}

		if $::realm == "labs" {
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
			case $::hostname {
				# manutius runs gmetad to get varnish data into torrus
				# unlike other servers, manutius uses the default rrd_rootdir
				# neon needs gmetad for ganglios
				/^manutius$/: {
					$data_sources = {
						"Upload caches eqiad" => "cp1021.eqiad.wmnet cp1022.eqiad.wmnet"
					}
					$rra_sizes = '"RRA:AVERAGE:0:1:4032" "RRA:AVERAGE:0.17:6:2016" "RRA:MAX:0.17:6:2016" "RRA:AVERAGE:0.042:288:732" "RRA:MAX:0.042:288:732"'
				}
				default: {
					$data_sources = {
						"Decommissioned servers pmtpa" => "eiximenis.wikimedia.org",
						"Video scalers pmtpa" => "tmh1.pmtpa.wmnet tmh2.pmtpa.wmnet",
						"Video scalers eqiad" => "tmh1001.eqiad.wmnet tmh1002.eqiad.wmnet",
						"Image scalers pmtpa" => "mw75.pmtpa.wmnet mw76.pmtpa.wmnet",
						"API application servers pmtpa" => "srv254.pmtpa.wmnet srv255.pmtpa.wmnet",
						"Application servers pmtpa" => "srv258.pmtpa.wmnet srv259.pmtpa.wmnet",
						"Jobrunners pmtpa" => "mw1.pmtpa.wmnet mw2.pmtpa.wmnet",
						"Image scalers eqiad" => "mw1153.eqiad.wmnet mw1154.eqiad.wmnet",
						"API application servers eqiad" => "mw1114.eqiad.wmnet mw1115.eqiad.wmnet",
						"Application servers eqaid" => "mw1017.eqiad.wmnet mw1018.eqiad.wmnet",
						"Jobrunners eqiad " => "mw1001.eqiad.wmnet mw1002.eqiad.wmnet",
						"Bits application servers pmtpa" => "srv248.pmtpa.wmnet srv249.pmtpa.wmnet",
						"Bits application servers eqiad" => "mw1151.eqiad.wmnet mw1152.eqiad.wmnet",
						"Search pmtpa" => "search13.pmtpa.wmnet search14.pmtpa.wmnet",
						"MySQL" => "db50.pmtpa.wmnet db51.pmtpa.wmnet",
						"PDF servers" => "pdf1.wikimedia.org pdf2.wikimedia.org",
						"Upload squids" => "sq41.wikimedia.org sq42.wikimedia.org",
						"API squids" => "sq31.wikimedia.org sq35.wikimedia.org",
						"LVS loadbalancers pmtpa" => "lvs1.wikimedia.org lvs2.wikimedia.org",
						"Miscellaneous" => "hooper.wikimedia.org tarin.pmtpa.wmnet",
						"Text squids" => "sq59.wikimedia.org sq60.wikimedia.org",
						"Bits caches" => "sq67.wikimedia.org sq68.wikimedia.org",
						"Fundraiser payments" => "payments1.wikimedia.org payments2.wikimedia.org",
						"Fundraising eqiad" => "pay-lvs1001.frack.eqiad.wmnet pay-lvs1002.frack.eqiad.wmnet",
						"SSL cluster" => "ssl1.wikimedia.org ssl2.wikimedia.org",
						"SSL cluster esams" => "ssl3001.esams.wikimedia.org ssl3002.esams.wikimedia.org",
						"Swift pmtpa" => "ms-fe1.pmtpa.wmnet ms-fe2.pmtpa.wmnet",
						"Virtualization cluster pmtpa" => "virt5.pmtpa.wmnet virt6.pmtpa.wmnet",
						"Glusterfs cluster pmtpa" => "labstore1.pmtpa.wmnet labstore2.pmtpa.wmnet",
						"MySQL eqiad" => "db1017.eqiad.wmnet db1021.eqiad.wmnet",
						"LVS loadbalancers eqiad" => "lvs1001.wikimedia.org lvs1002.wikimedia.org",
						"Miscellaneous eqiad" => "carbon.wikimedia.org ms1004.eqiad.wmnet",
						"Mobile caches eqiad" => "cp1043.wikimedia.org cp1044.wikimedia.org",
						"Bits caches eqiad" => "arsenic.wikimedia.org niobium.wikimedia.org",
						"Upload caches eqiad" => "cp1021.eqiad.wmnet cp1022.eqiad.wmnet",
						"SSL cluster eqiad" => "ssl1001.wikimedia.org ssl1002.wikimedia.org",
						"Swift eqiad" => "ms-fe1001.eqiad.wmnet, ms-fe1002.eqiad.wmnet",
						"Text squids eqiad" => "cp1001.eqiad.wmnet cp1002.eqiad.wmnet",
						"Search eqiad" => "search1001.eqiad.wmnet search1002.eqiad.wmnet",
						"Decommissioned servers esams" => "knsq1.esams.wikimedia.org",
						"Bits caches esams" => "cp3019.esams.wikimedia.org cp3020.esams.wikimedia.org",
						"Text squids esams" => "amssq31.esams.wikimedia.org amssq32.esams.wikimedia.org",
						"Upload squids esams" => "knsq16.esams.wikimedia.org knsq17.esams.wikimedia.org",
						"LVS loadbalancers esams" => "amslvs1.esams.wikimedia.org amslvs2.esams.wikimedia.org",
						"Miscellaneous esams" => "hooft.esams.wikimedia.org",
						"Analytics cluster eqiad" => "analytics1003.eqiad.wmnet analytics1011.eqiad.wmnet",
						"Memcached pmtpa" => "mc1.pmtpa.wmnet mc2.pmtpa.wmnet",
						"Memcached eqiad" => "mc1001.eqiad.wmnet mc1002.eqiad.wmnet",
						"Upload caches esams" => "cp3003.esams.wikimedia.org cp3004.esams.wikimedia.org",
						"Ceph cluster esams" => "ms-be3001.esams.wikimedia.org ms-be3002.esams.wikimedia.org",
						"Parsoid pmtpa" => "wtp1.pmtpa.wmnet",
						"Parsoid eqiad" => "wtp1001.eqiad.wmnet",
						"Parsoid Varnish pmtpa" => "constable.pmtpa.wmnet",
						"Parsoid Varnish eqiad" => "cerium.wikimedia.org",
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

		# for labs, gmond.conf and gmetad.conf are generated every 4 hours by a cron job
		if $::realm == "labs" {
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

	if $::realm == "labs" {
		$ganglia_servername = "ganglia.wmflabs.org"
		$ganglia_serveralias = "aggregator1.pmtpa.wmflabs"
		$ganglia_webdir = "/usr/share/ganglia-webfrontend"

		require ganglia::aggregator

	} else {
		$ganglia_servername = "ganglia.wikimedia.org"
		$ganglia_serveralias = "nickel.wikimedia.org ganglia3.wikimedia.org ganglia3-tip.wikimedia.org"
		# TODO(ssmollett): when switching to ganglia-webfrontend
		# package, use /usr/share/ganglia-webfrontend
		$ganglia_webdir = "/srv/org/wikimedia/ganglia-web-3.5.4+security"
		$ganglia_ssl_cert = "/etc/ssl/certs/star.wikimedia.org.pem"
		$ganglia_ssl_key = "/etc/ssl/private/star.wikimedia.org.key"
	}

	file {
		"/etc/apache2/sites-available/${ganglia_servername}":
			mode => 0444,
			owner => root,
			group => root,
			content => template("apache/sites/ganglia.wikimedia.org.erb"),
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
			mode => 0755,
			owner => nobody,
			group => root,
			ensure => directory;
		"/etc/rc.local":
			mode => 0555,
			owner => root,
			group => root,
			source => "puppet:///files/ganglia/rc.local",
			ensure => present;
	}

	apache_site { ganglia: name => $ganglia_servername }
	apache_module { rewrite: name => "rewrite" }

	package {
		"librrds-perl":
			before => Package[rrdtool],
			ensure => latest;
		"rrdtool":
			ensure => latest,
	}

	# back up rrds every half hour
	cron { "save-rrds":
		command => "/usr/local/bin/save-gmetad-rrds",
		user => root,
		minute => [ 7, 37 ],
		ensure => present
	}

	# Mount /mnt/ganglia_tmp as tmpfs to avoid Linux flushing mlocked
	# shm memory to disk
	$ganglia_tmp_mountpoint = "/mnt/ganglia_tmp"

	file { "$ganglia_tmp_mountpoint":
		mode => 0755,
		owner => root,
		group => root,
		ensure => directory;
	}

	mount { "$ganglia_tmp_mountpoint":
		require => File["$ganglia_tmp_mountpoint"],
		device => "tmpfs",
		fstype => "tmpfs",
		options => "noauto,noatime,defaults,size=3000m",
		pass => 0,
		dump => 0,
		ensure => mounted;
	}

	file { "${ganglia_tmp_mountpoint}/rrds.pmtpa":
		require => Mount["$ganglia_tmp_mountpoint"],
		mode => 0755,
		owner => nobody,
		group => root,
		ensure => directory;
	}


	# TODO(ssmollett): install ganglia-webfrontend package in production,
	# using appropriate conf.php
	if $::realm == "labs" {
		package { "ganglia-webfrontend":
			ensure => latest;
		}

		file { "/usr/share/ganglia-webfrontend/conf.php":
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/ganglia/conf.php",
			require => Package[ganglia-webfrontend],
			ensure => present;
		}
	}
}

class ganglia::logtailer {
	# this class pulls in everything necessary to get a ganglia-logtailer instance on a machine

	package { "ganglia-logtailer":
		ensure => latest;
	}
}

