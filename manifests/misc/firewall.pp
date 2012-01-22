class firewall::builder {
	file { 
		"/usr/local/fwbuilder.d":
		owner => root,
		group => root,
		mode => 0755,
		ensure => directory;
	}

	# collect all fw definitions
	Exported_acl_rule <<| |>>

	# TODO: add script here that does the work.

}

class firewall { 
	# for each inbound ACL create an exported file on the main server

	define exported_acl_rule($hostname=$::hostname, $ip_address=$::ipaddress, $protocol="tcp", $port) {
		file {
			"/usr/local/fwbuilder.d/${hostname}-${port}":
				content => "$hostname,$ipaddress,$protocol,$port\n",
				ensure => present,
				owner => root,
				group => root,
				tag => "inboundacl";
		}
	}
	# This is the definition called from all service manifests, e.g.
	# open_port { "mail": port => 25 }
	define open_port ($hostname=$hostname,$ip_address=$ipaddress, $protocol="tcp",$port) {
		}

		@@exported_acl_rule { $title: hostname => $hostname, ip_address => $ip_address, protocol => $protocol, port => $port }
}

class testcase1 {
	include firewall
	firewall::inboundacl {
	   "testbox":
			ip_address=>"1.2.3.4",
			port => 80;
	}
}

class testcase2 {
	include firewall
	firewall::inboundacl {
		"test2":
			ip_address=>"2.3.4.5",
			port => 80;
	}
}
