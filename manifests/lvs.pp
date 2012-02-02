# lvs.pp

import "generic-definitions.pp"

@monitor_group { "lvs": description => "LVS" }

# Global options
class lvs::configuration {

	$lvs_class_hosts = {
		'high-traffic1' => $::realm ? {
			'production' => $::site ? {
				'pmtpa' => [ "lvs2", "lvs6" ],
				'eqiad' => [ "lvs1001", "lvs1004" ],
				'esams' => [ "amslvs1", "amslvs3" ],
				default => undef,
			},
			'labs' => $::site ? {
				'pmtpa' => [ "i-00000051" ],
				default => undef,
			},
			default => undef,
		},
		'high-traffic2' => $::realm ? {
			'production' => $::site ? {
				'pmtpa' => [ "lvs1", "lvs5" ],
				'eqiad' => [ "lvs1002", "lvs1005" ],
				'esams' => [ "amslvs2", "amslvs4" ],
				default => undef,
			},
			'labs' => $::site ? {
				'pmtpa' => [ "i-00000051" ],
				default => undef,
			},
			default => undef,
		},
		# class https needs to be present on the same hosts as the corresponding
		# http services
		'https' => $::realm ? {
			'production' => $::site ? {
				'pmtpa' => [ 'lvs1', 'lvs2', 'lvs5', 'lvs6' ],
				'eqiad' => [ 'lvs1001', 'lvs1002', 'lvs1004', 'lvs1005' ],
				'esams' => [ 'amslvs1', 'amslvs2', 'amslvs3', 'amslvs4' ],
				default => undef,
			},
			'labs' => $::site ? {
				'pmtpa' => [ "i-00000051" ],
				default => undef,
			},
			default => undef,
		},
		'specials' => $::realm ? {
			'production' => [ "lvs1", "lvs2" ],
			'labs' => [ "i-00000051" ],
		},
		'low-traffic' => $::realm ? {
			'production' => $::site ? {
				'pmtpa' => [ "lvs3", "lvs4" ],
				'eqiad' => [ "lvs1003", "lvs1006" ],
				'esams' => [ ],
				default => undef,
			},
			'labs' => $::site ? {
				'pmtpa' => [ "i-00000051" ],
				default => undef,
			},
			default => undef,
		},
		'testing' => $::realm ? {
			'production' => [ "lvs1001", "lvs1004" ],
			'labs' => [ "i-00000051" ],
		},
	}

	$pybal = { 
		'bgp' => "yes",
		'bgp-peer-address' => $hostname ? {
			/^lvs[1-3]$/ => "208.80.152.197",
			/^lvs[4-6]$/ => "208.80.152.196",
			/^lvs100[1-3]$/ => "208.80.154.196",
			/^lvs100[4-6]$/ => "208.80.154.197",
			/^amslvs[12]$/ => "91.198.174.247",
			/^amslvs[34]$/ => "91.198.174.244",
			default => "(unspecified)"
			}
	}

	$idleconnection_monitor_options = {
		'timeout-clean-reconnect' => 3,
	        'max-delay' => 300
	}
	$runcommand_monitor_options = {
		'command' => "/bin/sh",
		'arguments' => "[ '/etc/pybal/runcommand/check-apache', server.host ]",
		'interval' => 60,
		'timeout' => 10,
	}

	# Configuration of PyBal LVS services.
	# NOTE! Double quotation may be needed for passing strings
	
	# NOTE! This hash is referenced in many other manifests
	$lvs_service_ips = {
		'production' => {
			'text' => {
				# TODO: remove old text ip addresses
				'pmtpa' => {
					'textsvc' => "10.2.1.25",
					'wikimedialb' => "208.80.152.200",
					'wikipedialb' => "208.80.152.201",
					'wiktionarylb' => "208.80.152.202",
					'wikiquotelb' => "208.80.152.203",
					'wikibookslb' => "208.80.152.204",
					'wikisourcelb' => "208.80.152.205",
					'wikinewslb' => "208.80.152.206",
					'wikiversitylb' => "208.80.152.207",
					'mediawikilb' => "208.80.152.208",
					'foundationlb' => "208.80.152.209"
				},
				'eqiad' => {
					'textsvc' => "10.2.2.25",
					'wikimedialb' => "208.80.154.224",
					'wikipedialb' => "208.80.154.225",
					'wiktionarylb' => "208.80.154.226",
					'wikiquotelb' => "208.80.154.227",
					'wikibookslb' => "208.80.154.228",
					'wikisourcelb' => "208.80.154.229",
					'wikinewslb' => "208.80.154.230",
					'wikiversitylb' => "208.80.154.231",
					'mediawikilb' => "208.80.154.232",
					'foundationlb' => "208.80.154.233"
				},
				'esams' => {
					'textsvc' => "10.2.3.25",
					'wikimedialb' => "91.198.174.224",
					'wikipedialb' => "91.198.174.225",
					'wiktionarylb' => "91.198.174.226",
					'wikiquotelb' => "91.198.174.227",
					'wikibookslb' => "91.198.174.228",
					'wikisourcelb' => "91.198.174.229",
					'wikinewslb' => "91.198.174.230",
					'wikiversitylb' => "91.198.174.231",
					'mediawikilb' => "91.198.174.232",
					'foundationlb' => "91.198.174.235"
				},
			},
			'https' => {
				'pmtpa' => {
					'wikimedialbsecure' => "208.80.152.200",
					'wikipedialbsecure' => "208.80.152.201",
					'bitslbsecure' => "208.80.152.210",
					'uploadlbsecure' => "208.80.152.211",
					'wiktionarylbsecure' => "208.80.152.202",
					'wikiquotelbsecure' => "208.80.152.203",
					'wikibookslbsecure' => "208.80.152.204",
					'wikisourcelbsecure' => "208.80.152.205",
					'wikinewslbsecure' => "208.80.152.206",
					'wikiversitylbsecure' => "208.80.152.207",
					'mediawikilbsecure' => "208.80.152.208",
					'foundationlbsecure' => "208.80.152.209"
				},
				'eqiad' => {
					'wikimedialbsecure' => "208.80.154.224",
					'wikipedialbsecure' => "208.80.154.225",
					'bitslbsecure' => "208.80.154.234",
					'uploadlbsecure' => "208.80.154.235",
					'wiktionarylbsecure' => "208.80.154.226",
					'wikiquotelbsecure' => "208.80.154.227",
					'wikibookslbsecure' => "208.80.154.228",
					'wikisourcelbsecure' => "208.80.154.229",
					'wikinewslbsecure' => "208.80.154.230",
					'wikiversitylbsecure' => "208.80.154.231",
					'mediawikilbsecure' => "208.80.154.232",
					'foundationlbsecure' => "208.80.154.233",
					'mobilelbsecure' => "208.80.154.236"
				},
				'esams' => {
					'wikimedialbsecure' => "91.198.174.224",
					'wikipedialbsecure' => "91.198.174.225",
					'bitslbsecure' => "91.198.174.233",
					'uploadlbsecure' => "91.198.174.234",
					'wiktionarylbsecure' => "91.198.174.226",
					'wikiquotelbsecure' => "91.198.174.227",
					'wikibookslbsecure' => "91.198.174.228",
					'wikisourcelbsecure' => "91.198.174.229",
					'wikinewslbsecure' => "91.198.174.230",
					'wikiversitylbsecure' => "91.198.174.231",
					'mediawikilbsecure' => '91.198.174.232',
					'foundationlbsecure' => "91.198.174.235"
				},
			},
			'bits' => {
				'pmtpa' => { 'bitslb' => "208.80.152.210", 'bitssvc' => "10.2.1.23" },
				'eqiad' => { 'bitslb' => "208.80.154.234", 'bitssvc' => "10.2.2.23" },
				'esams' => { 'bitslb' => "91.198.174.233", 'bitssvc' => "10.2.3.23" },
			},
			'upload' => {
				'pmtpa' => { 'uploadlb' => "208.80.152.211", 'uploadsvc' => "10.2.1.24" },
				'eqiad' => { 'uploadlb' => "208.80.154.235", 'uploadsvc' => "10.2.2.24" },
				'esams' => { 'uploadlb' => "91.198.174.234", 'uploadsvc' => "10.2.3.24" },
			},
			'apaches' => {
				'pmtpa' => "10.2.1.1",
				'eqiad' => "10.4.1.1",
			},
			'rendering' => {
				'pmtpa' => "10.2.1.21",
				'eqiad' => "10.2.2.21",
			},
			'api' => {
				'pmtpa' => "10.2.1.22",
				'eqiad' => "10.2.2.22",
			},
			'search_pool1' => {
				'pmtpa' => "10.2.1.11",
				'eqiad' => "10.2.2.11",
			},
			'search_pool2' => {
				'pmtpa' => "10.2.1.12",
				'eqiad' => "10.2.2.12",
			},
			'search_pool3' => {
				'pmtpa' => "10.2.1.13",
				'eqiad' => "10.2.2.13",
			},
			'mobile' => {
				'eqiad' => { 'mobile' => "208.80.154.236", 'mobilesvc' => "10.2.2.26"}
			},
			'swift' => {
				'pmtpa' => "10.2.1.27",
			}
		},
		'labs' => {
			'text' => {
				'pmtpa' => "10.4.0.4",
			},
			'apaches' => undef,
			'rendering' => undef,
			'api' => undef,
			'search_pool1' => undef,
			'search_pool2' => undef,
			'search_pool3' => undef,
		}
	}

	$service_ips = $lvs_service_ips[$::realm]

	$lvs_services = {
		"text" => {
			'description' => "Main wiki platform LVS service, text.${site}.wikimedia.org",
			'class' => "high-traffic1",
			'ip' => $service_ips['text'][$::site],
			'bgp' => "yes",
			'depool-threshold' => ".5",
			'monitors' => {
				'ProxyFetch' => {
					'url' => [ 'http://en.wikipedia.org/wiki/Main_Page' ],
				},
				'IdleConnection' => $idleconnection_monitor_options
			},
		},
		"https" => {
			'description' => "HTTPS services",
			'class' => "https",
			'ip' => $service_ips['https'][$::site],
			'port' => 443,
			'scheduler' => 'sh',
			# These IPs are announced by the corresponding HTTP services
			'bgp' => "no",
			'depool-threshold' => ".5",
			'monitors' => {
				#'ProxyFetch' => {
				#	 'url' => [ 'https://meta.wikimedia.org/wiki/Main_Page' ],
				#	 },
				'IdleConnection' => $idleconnection_monitor_options
			},
		},
		"bits" => {
			'description' => "Site assets (CSS/JS) LVS service, bits.${site}.wikimedia.org",
			'class' => "high-traffic1",
			'ip' => $service_ips['bits'][$::site],
			'bgp' => "yes",
			'depool-threshold' => ".5",
			'monitors' => {
				'ProxyFetch' => {
					'url' => [ 'http://bits.wikimedia.org/pybal-test-file' ],
					},
				'IdleConnection' => $idleconnection_monitor_options
			},
		},
		"upload" => {
			'description' => "Images and other media, upload.${site}.wikimedia.org",
			'class' => "high-traffic2",
			'ip' => $service_ips['upload'][$::site],
			'bgp' => "yes",
			'depool-threshold' => ".5",
			'monitors' => {
				'ProxyFetch' => {
					'url' => [ 'http://upload.wikimedia.org/pybaltestfile.txt' ],
					},
				'IdleConnection' => $idleconnection_monitor_options
			},
		},
		"mobile" => {
			'description' => "MediaWiki based mobile site",
			'class' => "testing",
			'ip' => $service_ips['mobile'][$::site],
			'bgp' => "yes",
			'depool-threshold' => ".6",
			'monitors' => {
				'ProxyFetch' => {
					'url' => [ 'http://en.m.wikipedia.org/wiki/Angelsberg' ],
					},
				'IdleConnection' => $idleconnection_monitor_options
			},
		},
		"payments" => {
			'description' => "Payments cluster, HTTPS payments.wikimedia.org",
			'class' => "high-traffic2",
			'ip' => "208.80.152.213",
			'port' => 443,
			'scheduler' => 'sh',
			'bgp' => "yes",
			'depool-threshold' => ".5",
			'monitors' => {
				'ProxyFetch' => {
					'url' => [ 'https://payments.wikimedia.org/index.php' ],
					},
				'IdleConnection' => $idleconnection_monitor_options
			},
		},
		"apaches" => {
			'description' => "Main MediaWiki application server cluster, appservers.svc.pmtpa.wmnet",
			'class' => "low-traffic",
			'ip' => $service_ips['apaches'][$::site],
			'bgp' => "yes",
			'depool-threshold' => ".6",
			'monitors' => {
				'ProxyFetch' => {
					'url' => [ 'http://en.wikipedia.org/wiki/Main_Page' ],
					},
				'IdleConnection' => $idleconnection_monitor_options,
				'RunCommand' => $runcommand_monitor_options
			},
		},
		"rendering" => {
			'description' => "MediaWiki thumbnail rendering cluster, rendering.svc.pmtpa.wmnet",
			'class' => "low-traffic",
			'ip' => $service_ips['rendering'][$::site],
			'bgp' => "yes",
			'depool-threshold' => ".74",
			'monitors' => {
				'ProxyFetch' => {
					'url' => [ 'http://en.wikipedia.org/favicon.ico' ],
					},
				'IdleConnection' => $idleconnection_monitor_options,
				'RunCommand' => $runcommand_monitor_options
			},
		},
		"api" => {
			'description' => "MediaWiki API cluster, api.svc.pmtpa.wmnet",
			'class' => "low-traffic",
			'ip' => $service_ips['api'][$::site],
			'bgp' => "yes",
			'depool-threshold' => ".6",
			'monitors' => {
				'ProxyFetch' => {
					'url' => [ 'http://en.wikipedia.org/w/api.php' ],
					},
				'IdleConnection' => $idleconnection_monitor_options,
				'RunCommand' => $runcommand_monitor_options
			},
		},
		"search_pool1" => {
			'description' => "Lucene search pool 1, search-pool1.svc.pmtpa.wmnet",
			'class' => "low-traffic",
			'protocol' => "tcp",
			'ip' => $service_ips['search_pool1'][$::site],
			'port' => 8123,
			'scheduler' => "wrr",
			'bgp' => "yes",
			'depool-threshold' => ".5",
			'monitors' => {
				'ProxyFetch' => {
					'url' => [ 'http://localhost/stats' ],
					},
				'IdleConnection' => $idleconnection_monitor_options,
			},
		},
		"search_pool2" => {
			'description' => "Lucene search pool 2, search-pool2.svc.pmtpa.wmnet",
			'class' => "low-traffic",
			'protocol' => "tcp",
			'ip' => $service_ips['search_pool2'][$::site],
			'port' => 8123,
			'scheduler' => "wrr",
			'bgp' => "yes",
			'depool-threshold' => "1",
			'monitors' => {
				'ProxyFetch' => {
					'url' => [ 'http://localhost/stats' ],
					},
				'IdleConnection' => $idleconnection_monitor_options,
			},
		},
		"search_pool3" => {
			'description' => "Lucene search pool 3, search-pool3.svc.pmtpa.wmnet",
			'class' => "low-traffic",
			'protocol' => "tcp",
			'ip' => $service_ips['search_pool3'][$::site],
			'port' => 8123,
			'scheduler' => "wrr",
			'bgp' => "yes",
			'depool-threshold' => "1",
			'monitors' => {
				'ProxyFetch' => {
					'url' => [ 'http://localhost/stats' ],
					},
				'IdleConnection' => $idleconnection_monitor_options,
			},
		},
		"swift" => {
			'description' => "Swift object store for thumbnails",
			'class' => "low-traffic",
			'ip' => $service_ips['swift'][$::site],
			'bgp' => "yes",
			'depool-threshold' => ".5",
			'monitors' => {
				'ProxyFetch' => {
					'url' => [ 'http://ms-fe.pmtpa.wmnet/wikipedia/commons/thumb/a/a2/Little_kitten_.jpg/80px-Little_kitten_.jpg' ],
					},
				'IdleConnection' => $idleconnection_monitor_options,
			},
		},
	}
}


class lvs::balancer {
	require "lvs::configuration"
	
	$lvs_class_hosts = $lvs::configuration::lvs_class_hosts
	$pybal = $lvs::configuration::pybal
	$lvs_services = $lvs::configuration::lvs_services
	
	if $::realm == "labs" {
		# Hack for arrays in LDAP - you suck puppet
		$lvs_balancer_ips = split(get_var('lvs_balancer_ips'), ',')
	}
	$lvs_realserver_ips = $lvs_balancer_ips

	system_role { "lvs::balancer": description => "LVS balancer" }

	package { [ ipvsadm, pybal, ethtool ]:
		ensure => installed;
	}

	# Generate PyBal config file
	file { "/etc/pybal/pybal.conf":
		require => Package[pybal],
		content => template("pybal/pybal.conf.erb")
	}

	# Needs an optimized kernel
	package { "linux-image-2.6.36-1-server":
		ensure => installed;
	}

	# Tune the ip_vs conn_tab_bits parameter
	file { "/etc/modprobe.d/lvs.conf":
		content => "# This file is managed by Puppet!\noptions ip_vs conn_tab_bits=20\n";
	}

	# Bind balancer IPs to the loopback interface 
	include lvs::realserver

	# Sysctl settings
	class { "generic::sysctl::advanced-routing": ensure => absent }
	include generic::sysctl::lvs
}

# Supporting the PyBal RunCommand monitor
class lvs::balancer::runcommand {
	require lvs::balancer

	file {
		"/etc/pybal/runcommand":
			owner => root,
			group => root,
			mode => 0755,
			ensure => directory;
		"/etc/pybal/runcommand/check-apache":
			owner => root,
			group => root,
			mode => 0755,
			source => "puppet:///files/pybal/check-apache";
		"/root/.ssh/pybal-check":
			owner => root,
			group => root,
			mode => 0600,
			source => "puppet:///private/pybal/pybal-check";
	}
}

# Class: lvs::realserver
#
# Sets up a server to be used as a 'real server' by LVS
#
# Parameters:
#	- $realserver_ips
#		Array or hash (name => ip) of service IPs to answer on
# FIXME: dynamic lookup $lvs_realserver_ips
class lvs::realserver($realserver_ips=$lvs_realserver_ips) {
	if $::realm == "labs" {
		# FIXME: Hack for arrays in LDAP - you suck puppet
		$ips = split(get_var('lvs_realserver_ips'), ',')
	}
	else {
		$ips = $realserver_ips
	}
	file { "/etc/default/wikimedia-lvs-realserver":
		mode => 0444,
		owner => root,
		group => root,
		content => template("lvs/wikimedia-lvs-realserver.erb");
	}

	exec { "/usr/sbin/dpkg-reconfigure -p critical -f noninteractive wikimedia-lvs-realserver":
		require => Package["wikimedia-lvs-realserver"],
		path => "/bin:/sbin:/usr/bin:/usr/sbin",
		subscribe => File["/etc/default/wikimedia-lvs-realserver"],
		refreshonly => true;
	}

	package { wikimedia-lvs-realserver:
		ensure => latest,
		require => File["/etc/default/wikimedia-lvs-realserver"];
	}
}

class lvs::static_labs_ips {
	require "lvs::configuration"
	
	$lvs_class_hosts = $lvs::configuration::lvs_class_hosts
	$pybal = $lvs::configuration::pybal
	$lvs_services = $lvs::configuration::lvs_services

	# Hack because puppet is a broken piece of crap
	$text = $lvs_services["text"]

	interface_ip { "wikimedialb": interface => "eth0", address => $text['ip']['wikimedialb'] }
	interface_ip { "wikipedialb": interface => "eth0", address => $text['ip']['wikipedialb'] }
	interface_ip { "wiktionarylb": interface => "eth0", address => $text['ip']['wiktionarylb'] }
	interface_ip { "wikiquotelb": interface => "eth0", address => $text['ip']['wikiquotelb'] }
	interface_ip { "wikibookslb": interface => "eth0", address => $text['ip']['wikibookslb'] }
	interface_ip { "wikisourcelb": interface => "eth0", address => $text['ip']['wikisourcelb'] }
	interface_ip { "wikinewslb": interface => "eth0", address => $text['ip']['wikinewslb'] }
	interface_ip { "wikiversitylb": interface => "eth0", address => $text['ip']['wikiversitylb'] }
	interface_ip { "mediawikilb": interface => "eth0", address => $text['ip']['mediawikilb'] }
	interface_ip { "foundationlb": interface => "eth0", address => $text['ip']['foundationlb'] }

}

define monitor_service_lvs_custom ( $description="LVS", $ip_address, $port=80, $check_command, $retries=3 ) {
	# Virtual resource for the monitoring host
	@monitor_host { $title: ip_address => $ip_address, group => "lvs", critical => "true" }
	@monitor_service { $title: host => $title, group => "lvs", description => $description, check_command => $check_command, critical => "true", retries => $retries }
}

define monitor_service_lvs_http ( $ip_address, $check_command, $critical="true" ) {
	# Virtual resource for the monitoring host
	@monitor_host { $title: ip_address => $ip_address, group => "lvs", critical => "true" }
	@monitor_service { $title: host => $title, group => "lvs", description => "LVS HTTP", check_command => $check_command, critical => $critical }
}

define monitor_service_lvs_https ( $ip_address, $check_command, $port=443, $critical="true" ) {
	$title_https = "${title}_https"
	# Virtual resource for the monitoring host
	@monitor_host { $title_https: ip_address => $ip_address, group => "lvs", critical => "true" }
	@monitor_service { $title_https: host => $title, group => "lvs", description => "LVS HTTPS", check_command => $check_command, critical => $critical }
}

# FIXME: temporary hack
if $hostname == "spence" {
	monitor_service_lvs_http { "upload.esams.wikimedia.org": ip_address => "91.198.174.234", check_command => "check_http_upload" }
	monitor_service_lvs_https { "upload.esams.wikimedia.org": ip_address => "91.198.174.234", check_command => "check_https_upload", critical => "false" }
	monitor_service_lvs_http { "m.wikimedia.org": ip_address => "208.80.154.236", check_command => "check_http_mobile" }

	monitor_service_lvs_http { "appservers.svc.pmtpa.wmnet": ip_address => "10.2.1.1", check_command => "check_http_lvs!en.wikipedia.org!/wiki/Main_Page" }
	monitor_service_lvs_http { "api.svc.pmtpa.wmnet": ip_address => "10.2.1.22", check_command => "check_http_lvs!en.wikipedia.org!/wiki/Main_Page" }
	monitor_service_lvs_http { "rendering.svc.pmtpa.wmnet": ip_address => "10.2.1.21", check_command => "check_http_lvs!en.wikipedia.org!/wiki/Main_Page" }
	monitor_service_lvs_http { "ms-fe.pmtpa.wmnet": ip_address => "10.2.1.27", check_command => "check_http_lvs!ms-fe.pmtpa.wmnet!wikipedia/commons/thumb/2/22/Miedledorpf.jpg/180px-Miedledorpf.jpg" }
	monitor_service_lvs_custom { "search-pool1.svc.pmtpa.wmnet": ip_address => "10.2.1.11", port => 8123, description => "LVS Lucene", check_command => "check_lucene" }
	monitor_service_lvs_custom { "search-pool2.svc.pmtpa.wmnet": ip_address => "10.2.1.12", port => 8123, description => "LVS Lucene", check_command => "check_lucene" }
	monitor_service_lvs_custom { "search-pool3.svc.pmtpa.wmnet": ip_address => "10.2.1.13", port => 8123, description => "LVS Lucene", check_command => "check_lucene" }

	# pmtpa -lb addresses
	monitor_service_lvs_http { "wikimedia-lb.pmtpa.wikimedia.org": ip_address => "208.80.152.200", check_command => "check_http_lvs!meta.wikimedia.org!/wiki/Main_Page" }
	monitor_service_lvs_https { "wikimedia-lb.pmtpa.wikimedia.org": ip_address => "208.80.152.200", check_command => "check_https_url!meta.wikimedia.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_http { "wikipedia-lb.pmtpa.wikimedia.org": ip_address => "208.80.152.201", check_command => "check_http_lvs!en.wikipedia.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_https { "wikipedia-lb.pmtpa.wikimedia.org": ip_address => "208.80.152.201", check_command => "check_https_url!en.wikipedia.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_http { "wiktionary-lb.pmtpa.wikimedia.org": ip_address => "208.80.152.202", check_command => "check_http_lvs!en.wiktionary.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_https { "wiktionary-lb.pmtpa.wikimedia.org": ip_address => "208.80.152.202", check_command => "check_https_url!en.wiktionary.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_http { "wikiquote-lb.pmtpa.wikimedia.org": ip_address => "208.80.152.203", check_command => "check_http_lvs!en.wikiquote.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_https { "wikiquote-lb.pmtpa.wikimedia.org": ip_address => "208.80.152.203", check_command => "check_https_url!en.wikiquote.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_http { "wikibooks-lb.pmtpa.wikimedia.org": ip_address => "208.80.152.204", check_command => "check_http_lvs!en.wikibooks.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_https { "wikibooks-lb.pmtpa.wikimedia.org": ip_address => "208.80.152.204", check_command => "check_https_url!en.wikibooks.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_http { "wikisource-lb.pmtpa.wikimedia.org": ip_address => "208.80.152.205", check_command => "check_http_lvs!en.wikisource.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_https { "wikisource-lb.pmtpa.wikimedia.org": ip_address => "208.80.152.205", check_command => "check_https_url!en.wikisource.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_http { "wikinews-lb.pmtpa.wikimedia.org": ip_address => "208.80.152.206", check_command => "check_http_lvs!en.wikinews.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_https { "wikinews-lb.pmtpa.wikimedia.org": ip_address => "208.80.152.206", check_command => "check_https_url!en.wikinews.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_http { "wikiversity-lb.pmtpa.wikimedia.org": ip_address => "208.80.152.207", check_command => "check_http_lvs!en.wikiversity.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_https { "wikiversity-lb.pmtpa.wikimedia.org": ip_address => "208.80.152.207", check_command => "check_https_url!en.wikiversity.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_http { "mediawiki-lb.pmtpa.wikimedia.org": ip_address => "208.80.152.208", check_command => "check_http_lvs!mediawiki.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_https { "mediawiki-lb.pmtpa.wikimedia.org": ip_address => "208.80.152.208", check_command => "check_https_url!mediawiki.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_http { "foundation-lb.pmtpa.wikimedia.org": ip_address => "208.80.152.209", check_command => "check_http_lvs!wikimediafoundation.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_https { "foundation-lb.pmtpa.wikimedia.org": ip_address => "208.80.152.209", check_command => "check_https_url!wikimediafoundation.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_http { "bits.pmtpa.wikimedia.org": ip_address => "208.80.152.210", check_command => "check_http_lvs!bits.wikimedia.org!/skins-1.5/common/images/poweredby_mediawiki_88x31.png" }
	monitor_service_lvs_https { "bits.pmtpa.wikimedia.org": ip_address => "208.80.152.210", check_command => "check_https_url!bits.wikimedia.org!/skins-1.5/common/images/poweredby_mediawiki_88x31.png", critical => "false" }
	monitor_service_lvs_http { "upload.pmtpa.wikimedia.org": ip_address => "208.80.152.211", check_command => "check_http_upload" }
	monitor_service_lvs_https { "upload.pmtpa.wikimedia.org": ip_address => "208.80.152.211", check_command => "check_https_upload", critical => "false" }

	# esams -lb addresses
	monitor_service_lvs_http { "wikimedia-lb.esams.wikimedia.org": ip_address => "91.198.174.224", check_command => "check_http_lvs!meta.wikimedia.org!/wiki/Main_Page" }
	monitor_service_lvs_https { "wikimedia-lb.esams.wikimedia.org": ip_address => "91.198.174.224", check_command => "check_https_url!meta.wikimedia.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_http { "wikipedia-lb.esams.wikimedia.org": ip_address => "91.198.174.225", check_command => "check_http_lvs!en.wikipedia.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_https { "wikipedia-lb.esams.wikimedia.org": ip_address => "91.198.174.225", check_command => "check_https_url!en.wikipedia.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_http { "wiktionary-lb.esams.wikimedia.org": ip_address => "91.198.174.226", check_command => "check_http_lvs!en.wiktionary.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_https { "wiktionary-lb.esams.wikimedia.org": ip_address => "91.198.174.226", check_command => "check_https_url!en.wiktionary.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_http { "wikiquote-lb.esams.wikimedia.org": ip_address => "91.198.174.227", check_command => "check_http_lvs!en.wikiquote.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_https { "wikiquote-lb.esams.wikimedia.org": ip_address => "91.198.174.227", check_command => "check_https_url!en.wikiquote.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_http { "wikibooks-lb.esams.wikimedia.org": ip_address => "91.198.174.228", check_command => "check_http_lvs!en.wikibooks.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_https { "wikibooks-lb.esams.wikimedia.org": ip_address => "91.198.174.228", check_command => "check_https_url!en.wikibooks.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_http { "wikisource-lb.esams.wikimedia.org": ip_address => "91.198.174.229", check_command => "check_http_lvs!en.wikisource.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_https { "wikisource-lb.esams.wikimedia.org": ip_address => "91.198.174.229", check_command => "check_https_url!en.wikisource.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_http { "wikinews-lb.esams.wikimedia.org": ip_address => "91.198.174.230", check_command => "check_http_lvs!en.wikinews.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_https { "wikinews-lb.esams.wikimedia.org": ip_address => "91.198.174.230", check_command => "check_https_url!en.wikinews.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_http { "wikiversity-lb.esams.wikimedia.org": ip_address => "91.198.174.231", check_command => "check_http_lvs!en.wikiversity.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_https { "wikiversity-lb.esams.wikimedia.org": ip_address => "91.198.174.231", check_command => "check_https_url!en.wikiversity.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_http { "mediawiki-lb.esams.wikimedia.org": ip_address => "91.198.174.232", check_command => "check_http_lvs!mediawiki.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_https { "mediawiki-lb.esams.wikimedia.org": ip_address => "91.198.174.232", check_command => "check_https_url!mediawiki.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_http { "foundation-lb.esams.wikimedia.org": ip_address => "91.198.174.235", check_command => "check_http_lvs!wikimediafoundation.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_https { "foundation-lb.esams.wikimedia.org": ip_address => "91.198.174.235", check_command => "check_https_url!wikimediafoundation.org!/wiki/Main_Page", critical => "false" }
	monitor_service_lvs_http { "bits.esams.wikimedia.org": ip_address => "91.198.174.233", check_command => "check_http_lvs!bits.wikimedia.org!/skins-1.5/common/images/poweredby_mediawiki_88x31.png" }
	monitor_service_lvs_https { "bits.esams.wikimedia.org": ip_address => "91.198.174.233", check_command => "check_https_url!bits.wikimedia.org!/skins-1.5/common/images/poweredby_mediawiki_88x31.png", critical => "false" }

	monitor_service_lvs_custom { "payments.wikimedia.org": ip_address => "208.80.152.213", port => 443, check_command => "check_https_url!payments.wikimedia.org!/index.php/Special:PayflowProGateway?uselang=en", retries => 20 }

	# Not really LVS but similar:

	# FIXME: hostnames can't have spaces
	#monitor_service_lvs_http { "ipv6 upload.esams.wikimedia.org": ip_address => "2620:0:862:1::80:2", check_command => "check_http_upload" }
}
