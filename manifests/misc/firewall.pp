class firewall::builder {
	file { 
		"/usr/local/fwbuilder.d":
		owner => root,
		group => root,
		mode => 0755,
		ensure => directory;
	}

	# collect all fw definitions
	File <<| tag == 'inboundacl' |>>

	# TODO: add script here that does the work.

}

class firewall { 
	# for each inbound ACL create an exported file on the main server
	define inboundacl ($ip_address=$ipaddress, port=$port) {
		@@definition {
			file {
				"/usr/local/fwbuilder.d/${hostname}-${port}":
					content => "$hostname,$ipaddress,$protocol,$port\n",
					tag => "inboundacl";
			}
		}
	}
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
