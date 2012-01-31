# ganglia.pp
#
# Parameters:
#  - $deaf:			Is the gmond process an aggregator
#  - $cname:			Cluster / Cloud 's name
#  - $location:			Machine's location
#  - $mcast_address:		Multicast "cluster" to join and send data on
#  - $gridname:			Grid name
#  - $authority_url:		Authority URL for the grid
#  - $apache_conf:		Apache configuration filename
#  - $gmetad_conf:		gmetad configuration filename

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
		gridname = "wmflabs"
		authority_url = "http://ganglia.wmflabs.org"
		apache_conf = "ganglia.wmflabs.org"
		gmetad_conf = "gmetad-labs.conf"
	} else {
		gridname = "Wikimedia"
		authority_url = "http://ganglia.wikimedia.org"
		apache_conf = "ganglia.wikimedia.org"
		gmetad_conf = "gmetad.conf"
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

	# gmond.conf template variables
	$ipoct = $ganglia_clusters[$cluster]["ip_oct"]
	$mcast_address = "${ip_prefix}.${ipoct}"

	$clustername = $ganglia_clusters[$cluster][name]
	$cname = "${clustername}${name_suffix}"

	$authority_url = "http://ganglia.wikimedia.org"

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
		name	=> "/etc/ganglia/gmond-${cluster}.conf",
		owner	=> "root",
		group	=> "root",
		mode	=> 644,
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

	systemuser { gmetric: name => "gmetric", home => "/var/lib/gmetric", shell => "/bin/sh" }

	# Class for setting up the collector (gmetad)
	class collector {

		system_role { "ganglia::collector": description => "Ganglia gmetad aggregator" }

		package { "gmetad":
			ensure => latest;
		}

	## FIXME this file is a temp hack to get ganglia running. Needs to become
	## a template generated from information kept in puppet - Lcarr, 2012/01/03

		file { "/etc/ganglia/gmetad.conf":
			require	=> Package[gmetad],
			source	=> "puppet:///files/ganglia/${gmetad_conf}",
			mode	=> 0644,
			ensure	=> present
		}

		service { "gmetad":
			require => File["/etc/ganglia/gmetad.conf"],
			ensure	=> running;
		}
	}

	class aggregator {
	# for the machine class which listens on multicast and
	# collects all the ganglia information from other sources

		# This overrides the default ganglia-monitor script 
		# with one that starts up multiple instances of gmond
		file { "/etc/init.d/ganglia-monitor":
			source => "puppet:///files/ganglia/ganglia-monitor",
			mode   => 0755,
			ensure => present
		}
	}
}

class ganglia::web {
# Class for the ganglia frontend machine

	require ganglia::collector,
		generic::php5-gd,
		generic::webserver::php5-mysql,
		svn::client

	class {'generic::webserver::php5': ssl => 'true'; }

	file {
		"/etc/apache2/sites-available/${apache_conf}":
			mode => 644,
			owner => root,
			group => root,
			source => "puppet:///files/apache/sites/${apache_conf}",
			ensure => present;
		"/usr/local/bin/restore-gmetad-rrds":
			mode => 755,
			owner => root,
			group => root,
			source => "puppet:///files/ganglia/restore-gmetad-rrds",
			ensure => present;
		"/usr/local/bin/save-gmetad-rrds":
			mode => 755,
			owner => root,
			group => root,
			source => "puppet:///files/ganglia/save-gmetad-rrds",
			ensure => present;
		"/etc/init.d/gmetad":
			mode => 755,
			owner => root,
			group => root,
			source => "puppet:///files/ganglia/gmetad",
			ensure => present;
		"/var/lib/ganglia/rrds.pmtpa/":
			ensure => directory;
		"/etc/rc.local":
			mode => 755,
			owner => root,
			group => root,
			source => "puppet:///files/ganglia/rc.local",
			ensure => present;
	}

	apache_site { ganglia: name => $apache_conf }
	apache_module { rewrite: name => "rewrite" }

	package {
		"librrds-perl":
			before => Package[rrdtool],
			ensure => latest;
		"rrdtool":
			ensure => latest;
	}

        if $realm == "labs" {
		package {
			"ganglia-webfrontend":
			ensure => latest;
		}
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
