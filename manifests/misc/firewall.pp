class firewall::builder {

	package { fwconfigtool:
		  ensure => latest;
	}
	file { 
		"/usr/local/fwconfigtool.d":
			owner => root,
			group => root,
			mode => 0755,
			ensure => directory;

		"/usr/share/fwconfigtool":
			owner => root,
			group => root,
			mode => 0755,
			ensure => directory;
	}

	# collect all fw definitions
	Exported_acl_rule <<| |>>

	cron { fwconfigtool_hourly :
			command => "/usr/bin/fwconfigtool /usr/share/fwconfigtool/junos_fw_output.slax /usr/local/fwconfigtool.d",
			minute => 30,
			ensure => present;
	} 

}

class firewall { 
	# for each inbound ACL create an exported file on the main server

	# This is the definition called from all service manifests, e.g.
	# open_port { "mail": port => 25 }

	define open_port ($hostname=$hostname,$ip_address=$ipaddress, $protocol="tcp",$port) {
		@@exported_acl_rule { $title: 
			hostname => $hostname,
			ip_address => $ip_address,
			protocol => $protocol,
			port => $port 
		}
	}

	define exported_acl_rule($hostname=$::hostname, $ip_address=$::ipaddress, $protocol="tcp", $port) {
		file {
			"/usr/local/fwconfigtool.d/${ipaddress}-${port}":
				content => "$hostname,$ipaddress,$protocol,$port\n",
				ensure => present,
				owner => root,
				group => root,
				tag => "inboundacl";
		}
	}

}

class testcase1 {
	include firewall
	firewall::open_port {
		"testbox":
			port => 80;
	}
	firewall::open_port {
		"test2":
			port => 443;
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
