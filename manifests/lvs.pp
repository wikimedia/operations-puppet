# lvs.pp

import "generic-definitions.pp"

@monitor_group { "lvs": description => "LVS" }

# Global options
$lvs_class_hosts = {
	'high-traffic1' => $site ? {
		'pmtpa' => [ "lvs2", "lvs6" ],
		'eqiad' => [ "lvs1001", "lvs1004" ],
		'esams' => [ "amslvs1", "amslvs3" ],
		default => undef,
	},
	'high-traffic2' => $site ? {
		'pmtpa' => [ "lvs1", "lvs5" ],
		'eqiad' => [ "lvs1002", "lvs1005" ],
		'esams' => [ "amslvs2", "amslvs4" ],
		default => undef,
	},
	# class https needs to be present on the same hosts as the corresponding
	# http services
	'https' => $site ? {
		'pmtpa' => [ 'lvs1', 'lvs2', 'lvs5', 'lvs6' ],
		'eqiad' => [ 'lvs1001', 'lvs1002', 'lvs1004', 'lvs1005' ],
		'esams' => [ 'amslvs1', 'amslvs2', 'amslvs3', 'amslvs4' ],
		default => undef,
	},
	'specials' => [ "lvs1", "lvs2" ],
	'low-traffic' => $site ? {
		'pmtpa' => [ "lvs3", "lvs4" ],
		'eqiad' => [ "lvs1003", "lvs1006" ],
		default => undef,
	},
	'testing' => [ "lvs1001", "lvs1004" ],
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
$lvs_services = {
	"text" => {
		'description' => "Main wiki platform LVS service, text.${site}.wikimedia.org",
		'class' => "high-traffic1",
		'ip' => $site ? {
			'pmtpa' => { 'text' => "208.80.152.2", 'textsvc' => "10.2.1.25", 'wikimedialb' => "208.80.152.200", 'wikipedialb' => "208.80.152.201", 'wiktionarylb' => "208.80.152.202", 'wikiquotelb' => "208.80.152.203", 'wikibookslb' => "208.80.152.204", 'wikisourcelb' => "208.80.152.205", 'wikinewslb' => "208.80.152.206", 'wikiversitylb' => "208.80.152.207", 'mediawikilb' => "208.80.152.208", 'foundationlb' => "208.80.152.209" },
			'eqiad' => { 'textsvc' => "10.2.4.25", 'wikimedialb' => "208.80.154.224", 'wikipedialb' => "208.80.154.225", 'wiktionarylb' => "208.80.154.226", 'wikiquotelb' => "208.80.154.227", 'wikibookslb' => "208.80.154.228", 'wikisourcelb' => "208.80.154.229", 'wikinewslb' => "208.80.154.230", 'wikiversitylb' => "208.80.154.231", 'mediawikilb' => "208.80.154.232", 'foundationlb' => "208.80.154.233" },
			'esams' => { 'text' => "91.198.174.232", 'textsvc' => "10.2.3.25", 'wikimedialb' => "91.198.174.224", 'wikipedialb' => "91.198.174.225", 'wiktionarylb' => "91.198.174.226", 'wikiquotelb' => "91.198.174.227", 'wikibookslb' => "91.198.174.228", 'wikisourcelb' => "91.198.174.229", 'wikinewslb' => "91.198.174.230", 'wikiversitylb' => "91.198.174.231", 'foundationlb' => "91.198.174.235" },
			default => undef,
		},
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
		'ip' => $site ? {
			'pmtpa' => { 'wikimedialbsecure' => "208.80.152.200", 'wikipedialbsecure' => "208.80.152.201", 'bitssecure' => "208.80.152.118", 'bitslbsecure' => "208.80.152.210", 'uploadsecure' => "208.80.152.3", 'uploadlbsecure' => "208.80.152.211", 'wiktionarylbsecure' => "208.80.152.202", 'wikiquotelbsecure' => "208.80.152.203", 'wikibookslbsecure' => "208.80.152.204", 'wikisourcelbsecure' => "208.80.152.205", 'wikinewslbsecure' => "208.80.152.206", 'wikiversitylbsecure' => "208.80.152.207", 'mediawikilbsecure' => "208.80.152.208", 'foundationlbsecure' => "208.80.152.209" },
			'eqiad' => { 'wikimedialbsecure' => "208.80.154.224", 'wikipedialbsecure' => "208.80.154.225", 'bitslbsecure' => "208.80.154.234", 'uploadlbsecure' => "208.80.154.235", 'wiktionarylbsecure' => "208.80.154.226", 'wikiquotelbsecure' => "208.80.154.227", 'wikibookslbsecure' => "208.80.154.228", 'wikisourcelbsecure' => "208.80.154.229", 'wikinewslbsecure' => "208.80.154.230", 'wikiversitylbsecure' => "208.80.154.231", 'mediawikilbsecure' => "208.80.154.232", 'foundationlbsecure' => "208.80.154.233" },
			'esams' => { 'wikimedialbsecure' => "91.198.174.224", 'wikipedialbsecure' => "91.198.174.225", 'bitssecure' => "91.198.174.233", 'uploadsecure' => "91.198.174.234", 'wiktionarylbsecure' => "91.198.174.226", 'wikiquotelbsecure' => "91.198.174.227", 'wikibookslbsecure' => "91.198.174.228", 'wikisourcelbsecure' => "91.198.174.229", 'wikinewslbsecure' => "91.198.174.230", 'wikiversitylbsecure' => "91.198.174.231", 'foundationlbsecure' => "91.198.174.235" },
			default => undef,
		},
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
		'ip' => $site ? {
			'pmtpa' => { 'bits' => "208.80.152.118", 'bitslb' => "208.80.152.210", 'bitssvc' => "10.2.1.23" },
			'eqiad' => { 'bits' => "208.80.154.234", 'bitssvc' => "10.2.4.23" },
			'esams' => { 'bits' => "91.198.174.233", 'bitssvc' => "10.2.3.23" },
			default => undef,
		},
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
		'ip' => $site ? {
			'pmtpa' => { 'upload' => "208.80.152.3", 'uploadlb' => "208.80.152.211", 'uploadsvc' => "10.2.1.24" },
			'eqiad' => { 'upload' => "208.80.154.235", 'uploadsvc' => "10.2.4.24" },
			'esams' => { 'upload' => "91.198.174.234", 'uploadsvc' => "10.2.3.24" },
			default => undef,
		},
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
		'description' => "Mobile site, m.wikimedia.org",
		'class' => "specials",
		'ip' => "208.80.152.5",
		'bgp' => "no",
		'depool-threshold' => ".6",
		'monitors' => {
			'ProxyFetch' => {
				'url' => [ 'http://en.m.wikipedia.org/wiki/Angelsberg' ],
				},
			'IdleConnection' => $idleconnection_monitor_options
			},
		},
	"new-mobile" => {
		'description' => "New PHP based mobile site",
		'class' => "testing",
		'ip' => "208.80.154.236",
		'bgp' => "yes",
		'depool-threshold' => ".6",
		'monitors' => {
			'ProxyFetch' => {
				'url' => [ 'http://en.m.wikipedia.org/wiki/Angelsberg' ],
				},
			'IdleConnection' => $idleconnection_monitor_options
			},
		},
	"owa" => {
		'description' => "OWA analytics, owa.wikimedia.org",
		'class' => "specials",
		'ip' => "208.80.152.6",
		'bgp' => "no",
		'depool-threshold' => ".5",
		'monitors' => {
			'ProxyFetch' => {
				'url' => [ 'http://owa.wikimedia.org/owa' ],
				},
			'IdleConnection' => $idleconnection_monitor_options
			},
		},
	"owas" => {
		'description' => "OWA analytics, HTTPS owa.wikimedia.org",
		'class' => "specials",
		'ip' => "208.80.152.6",
		'port' => 443,
		'scheduler' => 'sh',
		'bgp' => "no",
		'depool-threshold' => ".5",
		'monitors' => {
			'ProxyFetch' => {
				'url' => [ 'https://owa.wikimedia.org/owa' ],
				},
			'IdleConnection' => $idleconnection_monitor_options
			},
		},
	"payments" => {
		'description' => "Payments cluster, HTTPS payments.wikimedia.org",
		'class' => "specials",
		'ip' => "208.80.152.7",
		'port' => 443,
		'scheduler' => 'sh',
		'bgp' => "no",
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
		'ip' => $site ? {
			'pmtpa' => "10.2.1.1",
			'eqiad' => "10.4.1.1",
			default => undef,
		},
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
		'ip' => $site ? {
			'pmtpa' => "10.2.1.21",
			'eqiad' => "10.2.4.21",
			default => undef,
		},
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
		'ip' => $site ? {
			'pmtpa' => "10.2.1.22",
			'eqiad' => "10.2.4.22",
			default => undef,
		},
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
		'ip' => $site ? {
			'pmtpa' => "10.2.1.11",
			'eqiad' => "10.2.4.11",
			default => undef,
		},
		'port' => 8123,
		'scheduler' => "wrr",
		'bgp' => "yes",
		'depool-threshold' => "0",
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
		'ip' => $site ? {
			'pmtpa' => "10.2.1.12",
			'eqiad' => "10.2.4.12",
			default => undef,
		},
		'port' => 8123,
		'scheduler' => "wrr",
		'bgp' => "yes",
		'depool-threshold' => "0",
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
		'ip' => $site ? {
			'pmtpa' => "10.2.4.13",
			'eqiad' => "10.2.4.13",
			default => undef,
		},
		'port' => 8123,
		'scheduler' => "wrr",
		'bgp' => "yes",
		'depool-threshold' => "0",
		'monitors' => {
			'ProxyFetch' => {
				'url' => [ 'http://localhost/stats' ],
				},
			'IdleConnection' => $idleconnection_monitor_options,
			},
		},
	}


class lvs::balancer {
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

class lvs::realserver {
	file { "/etc/default/wikimedia-lvs-realserver":
		mode => 644,
		owner => root,
		group => root,
		content => template("lvs/wikimedia-lvs-realserver.erb");
	}

	exec { "/usr/sbin/dpkg-reconfigure -p critical -f noninteractive wikimedia-lvs-realserver":
		path => "/bin:/sbin:/usr/bin:/usr/sbin",
		subscribe => File["/etc/default/wikimedia-lvs-realserver"],
		refreshonly => true;
	}

	package { wikimedia-lvs-realserver:
		ensure => latest,
		require => File["/etc/default/wikimedia-lvs-realserver"];
	}
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

monitor_service_lvs_http { "text.pmtpa.wikimedia.org": ip_address => "208.80.152.2", check_command => "check_http_lvs!en.wikipedia.org!/wiki/Main_Page" }
monitor_service_lvs_http { "text.esams.wikimedia.org": ip_address => "91.198.174.232", check_command => "check_http_lvs!en.wikipedia.org!/wiki/Main_Page" }
monitor_service_lvs_http { "upload.esams.wikimedia.org": ip_address => "91.198.174.234", check_command => "check_http_upload" }
monitor_service_lvs_https { "upload.esams.wikimedia.org": ip_address => "91.198.174.234", check_command => "check_https_upload", critical => "false" }
monitor_service_lvs_http { "m.wikimedia.org": ip_address => "208.80.154.236", check_command => "check_http_mobile" }

monitor_service_lvs_http { "appservers.svc.pmtpa.wmnet": ip_address => "10.2.1.1", check_command => "check_http_lvs!en.wikipedia.org!/wiki/Main_Page" }
monitor_service_lvs_http { "api.svc.pmtpa.wmnet": ip_address => "10.2.1.22", check_command => "check_http_lvs!en.wikipedia.org!/wiki/Main_Page" }
monitor_service_lvs_http { "rendering.svc.pmtpa.wmnet": ip_address => "10.2.1.21", check_command => "check_http_lvs!en.wikipedia.org!/wiki/Main_Page" }
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
#monitor_service_lvs_http { "mediawiki-lb.esams.wikimedia.org": ip_address => "91.198.174.232", check_command => "check_http_lvs!mediawiki.org!/wiki/Main_Page", critical => "false" }
#monitor_service_lvs_https { "mediawiki-lb.esams.wikimedia.org": ip_address => "91.198.174.232", check_command => "check_https_url!mediawiki.org!/wiki/Main_Page", critical => "false" }
monitor_service_lvs_http { "foundation-lb.esams.wikimedia.org": ip_address => "91.198.174.235", check_command => "check_http_lvs!wikimediafoundation.org!/wiki/Main_Page", critical => "false" }
monitor_service_lvs_https { "foundation-lb.esams.wikimedia.org": ip_address => "91.198.174.235", check_command => "check_https_url!wikimediafoundation.org!/wiki/Main_Page", critical => "false" }
monitor_service_lvs_http { "bits.esams.wikimedia.org": ip_address => "91.198.174.233", check_command => "check_http_lvs!bits.wikimedia.org!/skins-1.5/common/images/poweredby_mediawiki_88x31.png" }
monitor_service_lvs_https { "bits.esams.wikimedia.org": ip_address => "91.198.174.233", check_command => "check_https_url!bits.wikimedia.org!/skins-1.5/common/images/poweredby_mediawiki_88x31.png", critical => "false" }

# Not really LVS but similar:

monitor_service_lvs_custom { "payments.wikimedia.org": ip_address => "208.80.152.7", port => 443, check_command => "check_https_url!payments.wikimedia.org!/index.php/Special:PayflowProGateway?uselang=en", retries => 20 }

monitor_service_lvs_http { "ipv6 upload.esams.wikimedia.org": ip_address => "2620:0:862:1::80:2", check_command => "check_http_upload" }
