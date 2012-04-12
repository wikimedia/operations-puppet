# ganglia.pp
#
# Parameters:
#  - $deaf:			Is the gmond process an aggregator
#  - $cname:			Cluster / Cloud 's name
#  - $location:			Machine's location
#  - $mcast_address:		Multicast "cluster" to join and send data on (not for labs)
#  - $gmetad_host:		Hostname or IP of gmetad server (for labs only)
#  - $authority_url:		URL referenced by gmond
#  - $gridname:			Grid name
#  - $gmetad_conf:		gmetad configuration filename (or stub for labs)
#  - $ganglia_servername:	Server name used by apache
#  - $ganglia_serveralias:	Server alias(es) used by apache


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
		$gridname = "wmflabs"
		$authority_url = "http://ganglia.wmflabs.org"
		$gmetad_host = "10.4.0.79"

	} else {
		$gridname = "Wikimedia"
		$authority_url = "http://ganglia.wikimedia.org"
	}
	
	$location = "unspecified"

	$ip_prefix = $site ? {
		"pmtpa" => "239.192.0",
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
		"cache_bits"	=> {
			"name"		=> "Bits caches",
			"ip_oct"	=> "21" },
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
					ensure => absent;
			}
		}
		ganglia-monitor: {
			package {
				"gmond":
					before => Package[ganglia-monitor],
					ensure => absent;
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
			$gmetad_conf = "gmetad.conf.labsstub"
		} else {
			$gmetad_conf = "gmetad.conf"
		}

		## FIXME this file is a temp hack to get ganglia running. Needs to become
		## a template generated from information kept in puppet - Lcarr, 2012/01/03

		file { "/etc/ganglia/${gmetad_conf}":
			require => Package[gmetad],
			source => $hostname ? {
				/^(streber|manutius)$/ => "puppet:///files/ganglia/gmetad.conf.torrus",
				default => "puppet:///files/ganglia/${gmetad_conf}"
			},
			mode => 0444,
			ensure	=> present
		}

		if $realm == "labs" {
			# cron job to generate ganglia aggregator confs
			exec { "create_gmond_conf_include":
				creates => "/etc/ganglia/conf.d/labs-aggregator.conf",
				command => "/usr/bin/touch /etc/ganglia/conf.d/labs-aggregator.conf";
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
				hour => [0, 8, 16],
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

	if $realm == "labs" {
		$ganglia_servername = "ganglia.wmflabs.org"
		$ganglia_serveralias = "aggregator1.pmtpa.wmflabs"

	} else {
		$ganglia_servername = "ganglia.wikimedia.org"
		$ganglia_serveralias = "nickel.wikimedia.org ganglia3.wikimedia.org ganglia3-tip.wikimedia.org"
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
		"/srv/org/":
			mode => 0755,
			owner => root,
			group => root,
			ensure => directory;
		"/srv/org/wikimedia/":
			mode => 0755,
			owner => root,
			group => root,
			ensure => directory;
		"/srv/org/wikimedia/gangliaweb/":
			mode => 0755,
			owner => root,
			group => root,
			ensure => directory;
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
		options => "noatime,defaults,size=3000m",
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

}

class ganglia::logtailer {
	# this class pulls in everything necessary to get a ganglia-logtailer instance on a machine

	package { "ganglia-logtailer":
		ensure => latest;
	}
}
