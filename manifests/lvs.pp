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

	# This needs to stay in place until the esams MX80 is in production
	# amslvs1 and amslvs2 currently can't have ipv6 enabled
	$ipv6_hosts = ["lvs1", "lvs2", "lvs3", "lvs4", "lvs5", "lvs6", "lvs1001", "lvs1002", "lvs1003", "lvs1004", "lvs1005", "lvs1006", "amslvs3", "amslvs4"]

	if $::ipaddress6_eth0 {
		$v6_ip = $::ipaddress6_eth0
	}
	else {
		$v6_ip = "::"
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
			},
		'bgp-nexthop-ipv4' => $::ipaddress_eth0,
		# FIXME: make a Puppet function, or fix facter
		'bgp-nexthop-ipv6' => inline_template("<%= require 'ipaddr'; (IPAddr.new(v6_ip).mask(64) | IPAddr.new(\"::\" + scope.lookupvar(\"::ipaddress\").gsub('.', ':'))).to_s() %>")
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
					'foundationlb' => "208.80.152.209",
					'wikidatalb' => "208.80.152.218",
					'wikivoyagelb' => "208.80.152.219"
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
					'foundationlb' => "208.80.154.233",
					'wikidatalb' => "208.80.154.242",
					'wikivoyagelb' => "208.80.154.243"
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
					'foundationlbsecure' => "208.80.152.209",
					'wikidatalbsecure' => "208.80.152.218",
					'wikivoyagelbsecure' => "208.80.152.219",

					'wikimedialbsecure6' => "2620:0:860:ed1a::0",
					'wikipedialbsecure6' => "2620:0:860:ed1a::1",
					'wiktionarylbsecure6' => "2620:0:860:ed1a::2",
					'wikiquotelbsecure6' => "2620:0:860:ed1a::3",
					'wikibookslbsecure6' => "2620:0:860:ed1a::4",
					'wikisourcelbsecure6' => "2620:0:860:ed1a::5",
					'wikinewslbsecure6' => "2620:0:860:ed1a::6",
					'wikiversitylbsecure6' => "2620:0:860:ed1a::7",
					'mediawikilbsecure6' => "2620:0:860:ed1a::8",
					'foundationlbsecure6' => "2620:0:860:ed1a::9",
					'bitslbsecure6' => "2620:0:860:ed1a::a",
					'uploadlbsecure6' => "2620:0:860:ed1a::b",
					'wikidatalbsecure6' => "2620:0:860:ed1a::12",
					'wikivoyagelbsecure6' => "2620:0:860:ed1a::13"
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
					'mobilelbsecure' => "208.80.154.236",
					'wikidatalbsecure' => "208.80.154.242",
					'wikivoyagelbsecure' => "208.80.154.243",

					'wikimedialbsecure6' => "2620:0:861:ed1a::0",
					'wikipedialbsecure6' => "2620:0:861:ed1a::1",
					'wiktionarylbsecure6' => "2620:0:861:ed1a::2",
					'wikiquotelbsecure6' => "2620:0:861:ed1a::3",
					'wikibookslbsecure6' => "2620:0:861:ed1a::4",
					'wikisourcelbsecure6' => "2620:0:861:ed1a::5",
					'wikinewslbsecure6' => "2620:0:861:ed1a::6",
					'wikiversitylbsecure6' => "2620:0:861:ed1a::7",
					'mediawikilbsecure6' => "2620:0:861:ed1a::8",
					'foundationlbsecure6' => "2620:0:861:ed1a::9",
					'bitslbsecure6' => "2620:0:861:ed1a::a",
					'uploadlbsecure6' => "2620:0:861:ed1a::b",
					'mobilelbsecure6' => "2620:0:861:ed1a::c",
					'wikidatalbsecure6' => "2620:0:861:ed1a::12",
					'wikivoyagelbsecure6' => "2620:0:861:ed1a::13"
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
					'foundationlbsecure' => "91.198.174.235",

					'wikimedialbsecure6' => "2620:0:862:ed1a::0",
					'wikipedialbsecure6' => "2620:0:862:ed1a::1",
					'wiktionarylbsecure6' => "2620:0:862:ed1a::2",
					'wikiquotelbsecure6' => "2620:0:862:ed1a::3",
					'wikibookslbsecure6' => "2620:0:862:ed1a::4",
					'wikisourcelbsecure6' => "2620:0:862:ed1a::5",
					'wikinewslbsecure6' => "2620:0:862:ed1a::6",
					'wikiversitylbsecure6' => "2620:0:862:ed1a::7",
					'mediawikilbsecure6' => "2620:0:862:ed1a::8",
					'foundationlbsecure6' => "2620:0:862:ed1a::9",
					'bitslbsecure6' => "2620:0:862:ed1a::a",
					'uploadlbsecure6' => "2620:0:862:ed1a::b",
				},
			},
			'ipv6' => {
				'pmtpa' => {
					'wikimedialb6' => "2620:0:860:ed1a::0",
					'wikipedialb6' => "2620:0:860:ed1a::1",
					'wiktionarylb6' => "2620:0:860:ed1a::2",
					'wikiquotelb6' => "2620:0:860:ed1a::3",
					'wikibookslb6' => "2620:0:860:ed1a::4",
					'wikisourcelb6' => "2620:0:860:ed1a::5",
					'wikinewslb6' => "2620:0:860:ed1a::6",
					'wikiversitylb6' => "2620:0:860:ed1a::7",
					'mediawikilb6' => "2620:0:860:ed1a::8",
					'foundationlb6' => "2620:0:860:ed1a::9",
					'uploadlb6' => "2620:0:860:ed1a::b",
					'wikidatalb6' => "2620:0:860:ed1a::12",
					'wikivoyagelb6' => "2620:0:860:ed1a::13"
				},
				'eqiad' => {
					'wikimedialb6' => "2620:0:861:ed1a::0",
					'wikipedialb6' => "2620:0:861:ed1a::1",
					'wiktionarylb6' => "2620:0:861:ed1a::2",
					'wikiquotelb6' => "2620:0:861:ed1a::3",
					'wikibookslb6' => "2620:0:861:ed1a::4",
					'wikisourcelb6' => "2620:0:861:ed1a::5",
					'wikinewslb6' => "2620:0:861:ed1a::6",
					'wikiversitylb6' => "2620:0:861:ed1a::7",
					'mediawikilb6' => "2620:0:861:ed1a::8",
					'foundationlb6' => "2620:0:861:ed1a::9",
					'wikidatalb6' => "2620:0:861:ed1a::12",
					'wikivoyagelb6' => "2620:0:861:ed1a::13"
				},
				'esams' => {
					'wikimedialb6' => "2620:0:862:ed1a::0",
					'wikipedialb6' => "2620:0:862:ed1a::1",
					'wiktionarylb6' => "2620:0:862:ed1a::2",
					'wikiquotelb6' => "2620:0:862:ed1a::3",
					'wikibookslb6' => "2620:0:862:ed1a::4",
					'wikisourcelb6' => "2620:0:862:ed1a::5",
					'wikinewslb6' => "2620:0:862:ed1a::6",
					'wikiversitylb6' => "2620:0:862:ed1a::7",
					'mediawikilb6' => "2620:0:862:ed1a::8",
					'foundationlb6' => "2620:0:862:ed1a::9",
					'uploadlb6' => "2620:0:862:ed1a::b",
				},
			},
			'bits' => {
				'pmtpa' => { 'bitslb' => "208.80.152.210", 'bitslb6' => "2620:0:860:ed1a::a", 'bitssvc' => "10.2.1.23" },
				'eqiad' => { 'bitslb' => "208.80.154.234", 'bitslb6' => "2620:0:861:ed1a::a", 'bitssvc' => "10.2.2.23" },
				'esams' => { 'bitslb' => "91.198.174.233", 'bitslb6' => "2620:0:862:ed1a::a", 'bitssvc' => "10.2.3.23" },
			},
			'upload' => {
				'pmtpa' => { 'uploadlb' => "208.80.152.211", 'uploadsvc' => "10.2.1.24" },
				'eqiad' => { 'uploadlb' => "208.80.154.235", 'uploadlb6' => "2620:0:861:ed1a::b", 'uploadsvc' => "10.2.2.24" },
				'esams' => { 'uploadlb' => "91.198.174.234", 'uploadsvc' => "10.2.3.24" },
			},
			'payments' => {
				'pmtpa' => "208.80.152.213",
				'eqiad' => "208.80.154.237",
			},
			'apaches' => {
				'pmtpa' => "10.2.1.1",
				'eqiad' => "10.2.2.1",
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
			'search_pool4' => {
				'pmtpa' => "10.2.1.14",
				'eqiad' => "10.2.2.14",
			},
			'search_pool5' => {
				'pmtpa' => "10.2.1.16",
				'eqiad' => "10.2.2.16",
			},
			'search_prefix' => {
				'pmtpa' => "10.2.1.15",
				'eqiad' => "10.2.2.15",
			},
			'search_pool5' => {
				'pmtpa' => "10.2.1.16",
				'eqiad' => "10.2.2.16",
			},
			'mobile' => {
				'eqiad' => { 'mobilelb' => "208.80.154.236", 'mobilelb6' => "2620:0:861:ed1a::c", 'mobilesvc' => "10.2.2.26"}
			},
			'swift' => {
				'pmtpa' => "10.2.1.27",
				'eqiad' => "10.2.2.27",
			},
			'dns_auth' => {
				'pmtpa' => "208.80.152.214",
				'eqiad' => "208.80.154.238",
			},
			'dns_rec' => {
				'pmtpa' => { 'dns_rec' => "208.80.152.215", 'dns_rec6' => "2620:0:860:ed1a::f" },
				'eqiad' => { 'dns_rec' => "208.80.154.239", 'dns_rec6' => "2620:0:861:ed1a::f" },
			},
			'osm' => {
				'pmtpa' => "208.80.152.216",
				'eqiad' => "208.80.154.240",
			},
			'misc_web' => {
				'pmtpa' => "208.80.152.217",
				'eqiad' => "208.80.154.241",
			},
			'parsoid' => {
				'pmtpa' => "10.2.1.28",
				'eqiad' => "10.2.2.28",
			},
			'parsoidcache' => {
				'pmtpa' => "10.2.1.29",
				'eqiad' => "10.2.2.29",
			},
		},
		'labs' => {
			'text' => {
				'pmtpa' => "10.4.0.4",
			},
			'apaches' => {
				'pmtpa' => "10.4.0.254",
			},
			'rendering' => {
				# Used to be 10.4.0.252
				'pmtpa' => [ '10.4.0.166', '10.4.0.187', ],
			},
			'api' => {
				'pmtpa' => "10.4.0.253",
			},
			'bits' => {
				'pmtpa' => "10.4.0.252",
			},
			'search_pool1' => {},
			'search_pool2' => {},
			'search_pool3' => {},
			'dns_auth' => {},
			'dns_rec' => {},
			'https' => {},
			'ipv6' => {},
			'misc_web' => {},
			'mobile' => {},
			'osm' => {},
			'search_pool1' => {},
			'search_pool2' => {},
			'search_pool3' => {},
			'search_pool4' => {},
			'search_pool5' => {},
			'search_poolbeta' => {},
			'search_prefix' => {},
			'swift' => {},
			'payments' => {},
			'upload' => {
				'pmtpa' => {
					'uploadlb'  => [ '10.4.0.166', '10.4.0.187', ],
					'uploadsvc' => [ '10.4.0.166', '10.4.0.187', ],
        },
			},
			'parsoid' => {},
			'parsoidcache' => {},
		}
	}

	$service_ips = $lvs_service_ips[$::realm]

	$lvs_services = {
		"text" => {
			'description' => "Main wiki platform LVS service, text.${::site}.wikimedia.org",
			'class' => "high-traffic1",
			'sites' => [ "pmtpa", "eqiad", "esams" ],
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
			'sites' => [ "pmtpa", "eqiad", "esams" ],
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
		"ipv6" => {
			'description' => "IPv6 proto proxies (for Squid port 80)",
			'class' => "https",
			'sites' => [ "pmtpa", "eqiad", "esams" ],
			'ip' => $service_ips['ipv6'][$::site],
			'port' => 80,
			'bgp' => "yes",
			'depool-threshold' => ".5",
			'monitors' => {
				'IdleConnection' => $idleconnection_monitor_options
			},
		},
		"bits" => {
			'description' => "Site assets (CSS/JS) LVS service, bits.${::site}.wikimedia.org",
			'class' => "high-traffic1",
			'sites' => [ "pmtpa", "eqiad", "esams" ],
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
			'description' => "Images and other media, upload.${::site}.wikimedia.org",
			'class' => "high-traffic2",
			'sites' => [ "pmtpa", "eqiad", "esams" ],
			'ip' => $service_ips['upload'][$::site],
			'bgp' => "yes",
			'depool-threshold' => ".5",
			'monitors' => {
				'ProxyFetch' => {
					'url' => [ 'http://upload.wikimedia.org/monitoring/backend' ],
					},
				'IdleConnection' => $idleconnection_monitor_options
			},
		},
		"mobile" => {
			'description' => "MediaWiki based mobile site",
			'class' => "testing",
			'sites' => [ "eqiad" ],
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
			'sites' => [ "pmtpa", "eqiad" ],
			'ip' => $service_ips['payments'][$::site],
			'port' => 443,
			'scheduler' => 'sh',
			'bgp' => "yes",
			'depool-threshold' => ".5",
			'monitors' => {
				'ProxyFetch' => {
					'url' => [ 'https://payments.wikimedia.org/index.php/Special:SystemStatus' ],
					},
				'IdleConnection' => $idleconnection_monitor_options
			},
		},
		"dns_auth" => {
			'description' => "Authoritative DNS",
			'class' => "high-traffic2",
			'sites' => [ "pmtpa", "eqiad" ],
			'protocol' => "udp",
			'ip' => $service_ips['dns_auth'][$::site],
			'port' => 53,
			'bgp' => "yes",
			'depool-threshold' => ".5",
			'monitors' => {
				'IdleConnection' => $idleconnection_monitor_options,
			},
		},
		"dns_rec" => {
			'description' => "Recursive DNS",
			'class' => "high-traffic2",
			'sites' => [ "pmtpa", "eqiad" ],
			'protocol' => "udp",
			'ip' => $service_ips['dns_rec'][$::site],
			'port' => 53,
			'bgp' => "yes",
			'depool-threshold' => ".5",
			'monitors' => {
				'DNSQuery' => {
					'hostnames' => [ 'en.wikipedia.org', 'www.google.com' ],
					'fail-on-nxdomain' => "no"
				},
				'IdleConnection' => $idleconnection_monitor_options,
			},
		},
		"osm" => {
			'description' => "OpenStreetMap tiles",
			'class' => "high-traffic2",
			'sites' => [ "pmtpa", "eqiad" ],
			'ip' => $service_ips['osm'][$::site],
			'bgp' => "yes",
			'depool-threshold' => ".5",
			'monitors' => {
				'IdleConnection' => $idleconnection_monitor_options
			},
		},
		"misc_web" => {
			'description' => "Miscellaneous web sites Varnish cluster",
			'class' => "high-traffic2",
			'sites' => [ "pmtpa", "eqiad" ],
			'ip' => $service_ips['misc_web'][$::site],
			'bgp' => "yes",
			'depool-threshold' => ".5",
			'monitors' => {
				'IdleConnection' => $idleconnection_monitor_options
			},
		},
		"apaches" => {
			'description' => "Main MediaWiki application server cluster, appservers.svc.pmtpa.wmnet",
			'class' => "low-traffic",
			'sites' => [ "pmtpa", "eqiad" ],
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
			'sites' => [ "pmtpa", "eqiad" ],
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
			'sites' => [ "pmtpa", "eqiad" ],
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
			'description' => "Lucene search pool 1",
			'class' => "low-traffic",
			'protocol' => "tcp",
			'sites' => [ "pmtpa", "eqiad" ],
			'ip' => $service_ips['search_pool1'][$::site],
			'port' => 8123,
			'scheduler' => "wrr",
			'bgp' => "yes",
			'depool-threshold' => ".3",
			'monitors' => {
				'ProxyFetch' => {
					'url' => [ 'http://localhost/stats' ],
					},
				'IdleConnection' => $idleconnection_monitor_options,
			},
		},
		"search_pool2" => {
			'description' => "Lucene search pool 2",
			'class' => "low-traffic",
			'protocol' => "tcp",
			'sites' => [ "pmtpa", "eqiad" ],
			'ip' => $service_ips['search_pool2'][$::site],
			'port' => 8123,
			'scheduler' => "wrr",
			'bgp' => "yes",
			'depool-threshold' => ".1",
			'monitors' => {
				'ProxyFetch' => {
					'url' => [ 'http://localhost/stats' ],
					},
				'IdleConnection' => $idleconnection_monitor_options,
			},
		},
		"search_pool3" => {
			'description' => "Lucene search pool 3",
			'class' => "low-traffic",
			'protocol' => "tcp",
			'sites' => [ "pmtpa", "eqiad" ],
			'ip' => $service_ips['search_pool3'][$::site],
			'port' => 8123,
			'scheduler' => "wrr",
			'bgp' => "yes",
			'depool-threshold' => ".1",
			'monitors' => {
				'ProxyFetch' => {
					'url' => [ 'http://localhost/stats' ],
					},
				'IdleConnection' => $idleconnection_monitor_options,
			},
		},
		"search_pool4" => {
			'description' => "Lucene search pool 4",
			'class' => "low-traffic",
			'protocol' => "tcp",
			'sites' => [ "pmtpa", "eqiad" ],
			'ip' => $service_ips['search_pool4'][$::site],
			'port' => 8123,
			'scheduler' => "wrr",
			'bgp' => "yes",
			'depool-threshold' => ".1",
			'monitors' => {
				'ProxyFetch' => {
					'url' => [ 'http://localhost/search/enwikinews/us?limit=1' ],
					},
				'IdleConnection' => $idleconnection_monitor_options,
			},
		},
		"search_pool5" => {
			'description' => "Lucene search pool 5",
			'class' => "low-traffic",
			'protocol' => "tcp",
			'sites' => [ "pmtpa", "eqiad" ],
			'ip' => $service_ips['search_pool5'][$::site],
			'port' => 8123,
			'scheduler' => "wrr",
			'bgp' => "yes",
			'depool-threshold' => ".1",
			'monitors' => {
				'ProxyFetch' => {
					'url' => [ 'http://localhost/search/commonswiki/cat?limit=1' ],
					},
				'IdleConnection' => $idleconnection_monitor_options,
			},
		},
		"search_prefix" => {
			'description' => "Lucene search prefix pool",
			'class' => "low-traffic",
			'protocol' => "tcp",
			'sites' => [ "pmtpa", "eqiad" ],
			'ip' => $service_ips['search_prefix'][$::site],
			'port' => 8123,
			'scheduler' => "wrr",
			'bgp' => "yes",
			'depool-threshold' => ".4",
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
			'sites' => [ "pmtpa", "eqiad" ],
			'ip' => $service_ips['swift'][$::site],
			'bgp' => "yes",
			'depool-threshold' => ".5",
			'monitors' => {
				'ProxyFetch' => {
					'url' => [ 'http://localhost/monitoring/backend' ],
					},
				'IdleConnection' => $idleconnection_monitor_options,
			},
		},
		"parsoid" => {
			'description' => "Parsoid wikitext parser for VisualEditor",
			'class' => "low-traffic",
			'sites' => [ "pmtpa", "eqiad" ],
			'ip' => $service_ips['parsoid'][$::site],
			'port' => 8000,
			'bgp' => "yes",
			'depool-threshold' => ".5",
			'monitors' => {
				'ProxyFetch' => {
					'url' => [ 'http://localhost:8000/' ],
				},
				'IdleConnection' => $idleconnection_monitor_options,
			},
		},
		'parsoidcache' => {
			'description' => "Varnish caches in front of Parsoid",
			'class' => "low-traffic",
			'sites' => [ "pmtpa", "eqiad" ],
			'ip' => $service_ips['parsoidcache'][$::site],
			'port' => 6081,
			'bgp' => "yes",
			'depool-threshold' => ".5",
			'monitors' => {
				'ProxyFetch' => {
					'url' => [ 'http://localhost:6081' ],
				},
				'IdleConnection' => $idleconnection_monitor_options,
			},
		},
	}
}

# Class: lvs::balancer
# Parameters:
#	- $service_ips: list of service IPs to bind to loopback
class lvs::balancer(
	$service_ips=[]
	) {

	require "lvs::configuration"
	include generic::sysfs::enable-rps

	$lvs_class_hosts = $lvs::configuration::lvs_class_hosts
	$ipv6_hosts = $lvs::configuration::ipv6_hosts
	$pybal = $lvs::configuration::pybal
	$lvs_services = $lvs::configuration::lvs_services

	system_role { "lvs::balancer": description => "LVS balancer" }

	package { [ ipvsadm, pybal, ethtool ]:
		ensure => installed;
	}

	# Generate PyBal config file
	file { "/etc/pybal/pybal.conf":
		require => Package[pybal],
		content => template("pybal/pybal.conf.erb");
	}

	# Tune the ip_vs conn_tab_bits parameter
	file { "/etc/modprobe.d/lvs.conf":
		content => "# This file is managed by Puppet!\noptions ip_vs conn_tab_bits=20\n";
	}

	# Bind balancer IPs to the loopback interface
	class { "lvs::realserver": realserver_ips => $service_ips }

	# Sysctl settings
	class { "generic::sysctl::advanced-routing": ensure => absent }
	include generic::sysctl::lvs
}

# Supporting the PyBal RunCommand monitor
class lvs::balancer::runcommand {
	Class[lvs::balancer] -> Class[lvs::balancer::runcommand]

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
class lvs::realserver($realserver_ips=[]) {

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

# FIXME: This definitely needs some smarter logic and cleaning up.

define monitor_service_lvs_custom ( $description="LVS", $ip_address, $port=80, $check_command, $retries=3 ) {
	# Virtual resource for the monitoring host
	@monitor_host { $title: ip_address => $ip_address, group => "lvs", critical => "true" }
	@monitor_service { $title: host => $title, group => "lvs", description => $description, check_command => $check_command, critical => "true", retries => $retries }
}

define monitor_service_lvs_http ( $ip_address, $check_command, $critical="true" ) {
	# Virtual resource for the monitoring host
	@monitor_host { $title: ip_address => $ip_address, group => "lvs", critical => "true" }
	@monitor_service { $title: host => $title, group => "lvs", description => "LVS HTTP IPv4", check_command => $check_command, critical => $critical }
}

define monitor_service_lvs_https ( $ip_address, $check_command, $port=443, $critical="true" ) {
	$title_https = "${title}_https"
	# Virtual resource for the monitoring host
	@monitor_host { $title_https: ip_address => $ip_address, group => "lvs", critical => "true" }
	@monitor_service { $title_https: host => $title, group => "lvs", description => "LVS HTTPS IPv4", check_command => $check_command, critical => $critical }
}

define monitor_service_lvs6_http_https ( $ip_address, $uri, $critical="true" ) {
	# Virtual resource for the monitoring host
	@monitor_host { "${title}_ipv6": ip_address => $ip_address, group => "lvs", critical => "true" }
	@monitor_service { "${title}_ipv6":
		host => "${title}_ipv6",
		group => "lvs",
		description => "LVS HTTP IPv6",
		check_command => "check_http_lvs!${uri}",
		critical => $critical
	}

	@monitor_host { "${title}_ipv6_https": ip_address => $ip_address, group => "lvs", critical => "true" }
	@monitor_service { "${title}_ipv6_https":
		host => "${title}_ipv6",
		group => "lvs",
		description => "LVS HTTPS IPv6",
		check_command => "check_https_url!${uri}",
		critical => $critical
	}
}

class lvs::monitor {
	include lvs::configuration

	$ip = $lvs::configuration::lvs_service_ips['production']

	monitor_service_lvs_http { "upload.esams.wikimedia.org": ip_address => "91.198.174.234", check_command => "check_http_upload" }
	monitor_service_lvs_https { "upload.esams.wikimedia.org": ip_address => "91.198.174.234", check_command => "check_https_upload", critical => "false" }
	monitor_service_lvs_http { "m.wikimedia.org": ip_address => "208.80.154.236", check_command => "check_http_mobile" }

	monitor_service_lvs_http { "appservers.svc.pmtpa.wmnet": ip_address => "10.2.1.1", check_command => "check_http_lvs!en.wikipedia.org!/wiki/Main_Page" }
	monitor_service_lvs_http { "appservers.svc.eqiad.wmnet": ip_address => "10.2.2.1", check_command => "check_http_lvs!en.wikipedia.org!/wiki/Main_Page" }
	monitor_service_lvs_http { "api.svc.pmtpa.wmnet": ip_address => "10.2.1.22", check_command => "check_http_lvs!en.wikipedia.org!/w/api.php?action=query&meta=siteinfo" }
	monitor_service_lvs_http { "api.svc.eqiad.wmnet": ip_address => "10.2.2.22", check_command => "check_http_lvs!en.wikipedia.org!/w/api.php?action=query&meta=siteinfo" }
	monitor_service_lvs_http { "rendering.svc.pmtpa.wmnet": ip_address => "10.2.1.21", check_command => "check_http_lvs!en.wikipedia.org!/wiki/Main_Page" }
	monitor_service_lvs_http { "rendering.svc.eqiad.wmnet": ip_address => "10.2.2.21", check_command => "check_http_lvs!en.wikipedia.org!/wiki/Main_Page" }
	monitor_service_lvs_http { "ms-fe.pmtpa.wmnet": ip_address => "10.2.1.27", check_command => "check_http_lvs!ms-fe.pmtpa.wmnet!/monitoring/backend" }
	#monitor_service_lvs_http { "ms-fe.eqiad.wmnet": ip_address => "10.2.2.27", check_command => "check_http_lvs!ms-fe.eqiad.wmnet!/monitoring/backend" }
	monitor_service_lvs_http { "parsoid.svc.pmtpa.wmnet": ip_address => "10.2.1.28", check_command => "check_http_on_port!8000" }
	monitor_service_lvs_http { "parsoid.svc.eqiad.wmnet": ip_address => "10.2.2.28", check_command => "check_http_on_port!8000" }
	monitor_service_lvs_http { "parsoidcache.svc.pmtpa.wmnet": ip_address => "10.2.1.29", check_command => "check_http_on_port!6081" }

	monitor_service_lvs_custom { "search-pool1.svc.pmtpa.wmnet": ip_address => "10.2.1.11", port => 8123, description => "LVS Lucene", check_command => "check_lucene" }
	monitor_service_lvs_custom { "search-pool2.svc.pmtpa.wmnet": ip_address => "10.2.1.12", port => 8123, description => "LVS Lucene", check_command => "check_lucene" }
	monitor_service_lvs_custom { "search-pool3.svc.pmtpa.wmnet": ip_address => "10.2.1.13", port => 8123, description => "LVS Lucene", check_command => "check_lucene" }
	monitor_service_lvs_custom { "search-pool4.svc.pmtpa.wmnet": ip_address => "10.2.1.14", port => 8123, description => "LVS Lucene", check_command => "check_lucene" }
	monitor_service_lvs_custom { "search-pool5.svc.pmtpa.wmnet": ip_address => "10.2.1.16", port => 8123, description => "LVS Lucene", check_command => "check_lucene" }
	monitor_service_lvs_custom { "search-prefix.svc.pmtpa.wmnet": ip_address => "10.2.1.15", port => 8123, description => "LVS Lucene", check_command => "check_lucene" }

	monitor_service_lvs_custom { "search-pool1.svc.eqiad.wmnet": ip_address => "10.2.2.11", port => 8123, description => "LVS Lucene", check_command => "check_lucene" }
	monitor_service_lvs_custom { "search-pool2.svc.eqiad.wmnet": ip_address => "10.2.2.12", port => 8123, description => "LVS Lucene", check_command => "check_lucene" }
	monitor_service_lvs_custom { "search-pool3.svc.eqiad.wmnet": ip_address => "10.2.2.13", port => 8123, description => "LVS Lucene", check_command => "check_lucene" }
	monitor_service_lvs_custom { "search-pool4.svc.eqiad.wmnet": ip_address => "10.2.2.14", port => 8123, description => "LVS Lucene", check_command => "check_lucene" }
	monitor_service_lvs_custom { "search-pool5.svc.eqiad.wmnet": ip_address => "10.2.2.16", port => 8123, description => "LVS Lucene", check_command => "check_lucene" }
	monitor_service_lvs_custom { "search-prefix.svc.eqiad.wmnet": ip_address => "10.2.2.15", port => 8123, description => "LVS Lucene", check_command => "check_lucene" }

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
	monitor_service_lvs_http { "wikidata-lb.pmtpa.wikimedia.org": ip_address => "208.80.152.218", check_command => "check_http_lvs!www.wikidata.org!/" }
	monitor_service_lvs_https { "wikidata-lb.pmtpa.wikimedia.org": ip_address => "208.80.152.218", check_command => "check_https_url!www.wikidata.org!/", critical => "false" }
	monitor_service_lvs_http { "wikivoyage-lb.pmtpa.wikimedia.org": ip_address => "208.80.152.219", check_command => "check_http_lvs!en.wikivoyage.org!/wiki/Main_Page" }
	monitor_service_lvs_https { "wikivoyage-lb.pmtpa.wikimedia.org": ip_address => "208.80.152.219", check_command => "check_https_url!wikivoyage.org!/wiki/Main_Page", critical => "false" }

	monitor_service_lvs6_http_https {
		"wikimedia-lb.pmtpa.wikimedia.org":
			ip_address => $ip['ipv6']['pmtpa']['wikimedialb6'],
			uri => "meta.wikimedia.org!/wiki/Main_Page",
			critical => "false";
		"wikipedia-lb.pmtpa.wikimedia.org":
			ip_address => $ip['ipv6']['pmtpa']['wikipedialb6'],
			uri => "en.wikipedia.org!/wiki/Main_Page";
		"wiktionary-lb.pmtpa.wikimedia.org":
			ip_address => $ip['ipv6']['pmtpa']['wiktionarylb6'],
			uri => "en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"wikiquote-lb.pmtpa.wikimedia.org":
			ip_address => $ip['ipv6']['pmtpa']['wikiquotelb6'],
			uri => "en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"wikibooks-lb.pmtpa.wikimedia.org":
			ip_address => $ip['ipv6']['pmtpa']['wikibookslb6'],
			uri => "en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"wikisource-lb.pmtpa.wikimedia.org":
			ip_address => $ip['ipv6']['pmtpa']['wikisourcelb6'],
			uri => "en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"wikinews-lb.pmtpa.wikimedia.org":
			ip_address => $ip['ipv6']['pmtpa']['wikinewslb6'],
			uri => "en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"wikiversity-lb.pmtpa.wikimedia.org":
			ip_address => $ip['ipv6']['pmtpa']['wikiversitylb6'],
			uri => "en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"mediawiki-lb.pmtpa.wikimedia.org":
			ip_address => $ip['ipv6']['pmtpa']['mediawikilb6'],
			uri => "en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"foundation-lb.pmtpa.wikimedia.org":
			ip_address => $ip['ipv6']['pmtpa']['foundationlb6'],
			uri => "en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"bits-lb.pmtpa.wikimedia.org":
			ip_address => $ip['bits']['pmtpa']['bitslb6'],
			uri => "bits.wikimedia.org!/skins-1.5/common/images/poweredby_mediawiki_88x31.png";
		"upload-lb.pmtpa.wikimedia.org":
			ip_address => $ip['ipv6']['pmtpa']['uploadlb6'],
			uri => "upload.wikimedia.org!/monitoring/backend";
		"wikidata-lb.pmtpa.wikimedia.org":
			ip_address => $ip['ipv6']['pmtpa']['wikidatalb6'],
			uri => "www.wikidata.org!/";
		"wikivoyage-lb.pmtpa.wikimedia.org":
			ip_address => $ip['ipv6']['pmtpa']['wikivoyagelb6'],
			uri => "en.wikivoyage.org!/wiki/Main_Page";

	}

	# eqiad -lb addresses
	monitor_service_lvs_http {
		"wikimedia-lb.eqiad.wikimedia.org":
			ip_address => $ip['text']['eqiad']['wikimedialb'],
			check_command => "check_http_lvs!meta.wikimedia.org!/wiki/Main_Page";
		"wikipedia-lb.eqiad.wikimedia.org":
			ip_address => $ip['text']['eqiad']['wikipedialb'],
			check_command => "check_http_lvs!en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"wiktionary-lb.eqiad.wikimedia.org":
			ip_address => $ip['text']['eqiad']['wiktionarylb'],
			check_command => "check_http_lvs!en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"wikiquote-lb.eqiad.wikimedia.org":
			ip_address => $ip['text']['eqiad']['wikiquotelb'],
			check_command => "check_http_lvs!en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"wikibooks-lb.eqiad.wikimedia.org":
			ip_address => $ip['text']['eqiad']['wikibookslb'],
			check_command => "check_http_lvs!en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"wikisource-lb.eqiad.wikimedia.org":
			ip_address => $ip['text']['eqiad']['wikisourcelb'],
			check_command => "check_http_lvs!en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"wikinews-lb.eqiad.wikimedia.org":
			ip_address => $ip['text']['eqiad']['wikinewslb'],
			check_command => "check_http_lvs!en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"wikiversity-lb.eqiad.wikimedia.org":
			ip_address => $ip['text']['eqiad']['wikiversitylb'],
			check_command => "check_http_lvs!en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"mediawiki-lb.eqiad.wikimedia.org":
			ip_address => $ip['text']['eqiad']['mediawikilb'],
			check_command => "check_http_lvs!en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"foundation-lb.eqiad.wikimedia.org":
			ip_address => $ip['text']['eqiad']['foundationlb'],
			check_command => "check_http_lvs!en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"bits-lb.eqiad.wikimedia.org":
			ip_address => $ip['bits']['eqiad']['bitslb'],
			check_command => "check_http_lvs!bits.wikimedia.org!/skins-1.5/common/images/poweredby_mediawiki_88x31.png";
		"upload-lb.eqiad.wikimedia.org":
			ip_address => $ip['upload']['eqiad']['uploadlb'],
			check_command => "check_http_lvs!upload.wikimedia.org!/monitoring/backend";
		"mobile-lb.eqiad.wikimedia.org":
			ip_address => $ip['mobile']['eqiad']['mobilelb'],
			check_command => "check_http_lvs!en.m.wikipedia.org!/wiki/Main_Page";
		"wikidata-lb.eqiad.wikimedia.org":
			ip_address => $ip['text']['eqiad']['wikidatalb'],
			check_command => "check_http_lvs!www.wikidata.org!/";
		"wikivoyage-lb.eqiad.wikimedia.org":
			ip_address => $ip['text']['eqiad']['wikivoyagelb'],
			check_command => "check_http_lvs!en.wikivoyage.org!/wiki/Main_Page";
	}

	monitor_service_lvs6_http_https {
		"wikimedia-lb.eqiad.wikimedia.org":
			ip_address => $ip['ipv6']['eqiad']['wikimedialb6'],
			uri => "meta.wikimedia.org!/wiki/Main_Page",
			critical => "false";
		"wikipedia-lb.eqiad.wikimedia.org":
			ip_address => $ip['ipv6']['eqiad']['wikipedialb6'],
			uri => "en.wikipedia.org!/wiki/Main_Page";
		"wiktionary-lb.eqiad.wikimedia.org":
			ip_address => $ip['ipv6']['eqiad']['wiktionarylb6'],
			uri => "en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"wikiquote-lb.eqiad.wikimedia.org":
			ip_address => $ip['ipv6']['eqiad']['wikiquotelb6'],
			uri => "en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"wikibooks-lb.eqiad.wikimedia.org":
			ip_address => $ip['ipv6']['eqiad']['wikibookslb6'],
			uri => "en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"wikisource-lb.eqiad.wikimedia.org":
			ip_address => $ip['ipv6']['eqiad']['wikisourcelb6'],
			uri => "en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"wikinews-lb.eqiad.wikimedia.org":
			ip_address => $ip['ipv6']['eqiad']['wikinewslb6'],
			uri => "en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"wikiversity-lb.eqiad.wikimedia.org":
			ip_address => $ip['ipv6']['eqiad']['wikiversitylb6'],
			uri => "en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"mediawiki-lb.eqiad.wikimedia.org":
			ip_address => $ip['ipv6']['eqiad']['mediawikilb6'],
			uri => "en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"foundation-lb.eqiad.wikimedia.org":
			ip_address => $ip['ipv6']['eqiad']['foundationlb6'],
			uri => "en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"bits-lb.eqiad.wikimedia.org":
			ip_address => $ip['bits']['eqiad']['bitslb6'],
			uri => "bits.wikimedia.org!/skins-1.5/common/images/poweredby_mediawiki_88x31.png";
		"upload-lb.eqiad.wikimedia.org":
			ip_address => $ip['upload']['eqiad']['uploadlb6'],
			uri => "upload.wikimedia.org!/monitoring/backend";
		"mobile-lb.eqiad.wikimedia.org":
			ip_address => $ip['mobile']['eqiad']['mobilelb6'],
			uri => "en.m.wikipedia.org!/wiki/Main_Page";
		"wikidata-lb.eqiad.wikimedia.org":
			ip_address => $ip['ipv6']['eqiad']['wikidatalb6'],
			uri => "www.wikidata.org!/";
		"wikivoyage-lb.eqiad.wikimedia.org":
			ip_address => $ip['ipv6']['eqiad']['wikivoyagelb6'],
			uri => "en.wikivoyage.org!/wiki/Main_Page";
	}

	monitor_service_lvs_https {
		"wikimedia-lb.eqiad.wikimedia.org":
			ip_address => $ip['text']['eqiad']['wikimedialb'],
			check_command => "check_https_url!meta.wikimedia.org!/wiki/Main_Page";
		"wikipedia-lb.eqiad.wikimedia.org":
			ip_address => $ip['text']['eqiad']['wikipedialb'],
			check_command => "check_https_url!meta.wikimedia.org!/wiki/Main_Page",
			critical => "false";
		"wiktionary-lb.eqiad.wikimedia.org":
			ip_address => $ip['text']['eqiad']['wiktionarylb'],
			check_command => "check_https_lvs!en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"wikiquote-lb.eqiad.wikimedia.org":
			ip_address => $ip['text']['eqiad']['wikiquotelb'],
			check_command => "check_https_lvs!en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"wikibooks-lb.eqiad.wikimedia.org":
			ip_address => $ip['text']['eqiad']['wikibookslb'],
			check_command => "check_https_lvs!en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"wikisource-lb.eqiad.wikimedia.org":
			ip_address => $ip['text']['eqiad']['wikisourcelb'],
			check_command => "check_https_lvs!en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"wikinews-lb.eqiad.wikimedia.org":
			ip_address => $ip['text']['eqiad']['wikinewslb'],
			check_command => "check_https_lvs!en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"wikiversity-lb.eqiad.wikimedia.org":
			ip_address => $ip['text']['eqiad']['wikiversitylb'],
			check_command => "check_https_lvs!en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"mediawiki-lb.eqiad.wikimedia.org":
			ip_address => $ip['text']['eqiad']['mediawikilb'],
			check_command => "check_https_lvs!en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"foundation-lb.eqiad.wikimedia.org":
			ip_address => $ip['text']['eqiad']['foundationlb'],
			check_command => "check_https_lvs!en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"bits-lb.eqiad.wikimedia.org":
			ip_address => $ip['bits']['eqiad']['bitslb'],
			check_command => "check_https_url!bits.wikimedia.org!/skins-1.5/common/images/poweredby_mediawiki_88x31.png";
		"upload-lb.eqiad.wikimedia.org":
			ip_address => $ip['upload']['eqiad']['uploadlb'],
			check_command => "check_https_url!upload.wikimedia.org!/monitoring/backend";
		"mobile-lb.eqiad.wikimedia.org":
			ip_address => $ip['mobile']['eqiad']['mobilelb'],
			check_command => "check_https_lvs!en.m.wikipedia.org!/wiki/Main_Page";
		"wikidata-lb.eqiad.wikimedia.org":
			ip_address => $ip['text']['eqiad']['wikidatalb'],
			check_command => "check_https_lvs!www.wikidata.org!/";
		"wikivoyage-lb.eqiad.wikimedia.org":
			ip_address => $ip['text']['eqiad']['wikivoyagelb'],
			check_command => "check_https_lvs!en.wikivoyage.org!/wiki/Main_Page";
	}

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

	# todo: we should probably monitor both eqiad/pmtpa
	monitor_service_lvs_custom { "payments.wikimedia.org": ip_address => "208.80.155.5", port => 443, check_command => "check_https_url!payments.wikimedia.org!/index.php/Special:SystemStatus", retries => 20 }

	monitor_service_lvs6_http_https {
		"wikimedia-lb.esams.wikimedia.org":
			ip_address => $ip['ipv6']['esams']['wikimedialb6'],
			uri => "meta.wikimedia.org!/wiki/Main_Page",
			critical => "false";
		"wikipedia-lb.esams.wikimedia.org":
			ip_address => $ip['ipv6']['esams']['wikipedialb6'],
			uri => "en.wikipedia.org!/wiki/Main_Page";
		"wiktionary-lb.esams.wikimedia.org":
			ip_address => $ip['ipv6']['esams']['wiktionarylb6'],
			uri => "en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"wikiquote-lb.esams.wikimedia.org":
			ip_address => $ip['ipv6']['esams']['wikiquotelb6'],
			uri => "en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"wikibooks-lb.esams.wikimedia.org":
			ip_address => $ip['ipv6']['esams']['wikibookslb6'],
			uri => "en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"wikisource-lb.esams.wikimedia.org":
			ip_address => $ip['ipv6']['esams']['wikisourcelb6'],
			uri => "en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"wikinews-lb.esams.wikimedia.org":
			ip_address => $ip['ipv6']['esams']['wikinewslb6'],
			uri => "en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"wikiversity-lb.esams.wikimedia.org":
			ip_address => $ip['ipv6']['esams']['wikiversitylb6'],
			uri => "en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"mediawiki-lb.esams.wikimedia.org":
			ip_address => $ip['ipv6']['esams']['mediawikilb6'],
			uri => "en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"foundation-lb.esams.wikimedia.org":
			ip_address => $ip['ipv6']['esams']['foundationlb6'],
			uri => "en.wikipedia.org!/wiki/Main_Page",
			critical => "false";
		"bits-lb.esams.wikimedia.org":
			ip_address => $ip['bits']['esams']['bitslb6'],
			uri => "bits.wikimedia.org!/skins-1.5/common/images/poweredby_mediawiki_88x31.png";
		"upload-lb.esams.wikimedia.org":
			ip_address => $ip['ipv6']['esams']['uploadlb6'],
			uri => "upload.wikimedia.org!/monitoring/backend";
	}

	# Not really LVS but similar:

	# FIXME: hostnames can't have spaces
	#monitor_service_lvs_http { "ipv6 upload.esams.wikimedia.org": ip_address => "2620:0:862:1::80:2", check_command => "check_http_upload" }
}
