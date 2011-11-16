# swift.pp

class swift::base {

	package { "swift":
		ensure => present;
	}

	file { "/etc/swift":
			ensure => directory,
			recurse => true,
			owner => swift,
			group => swift,
			mode => 0444;
		"/etc/swift/swift.conf":
			ensure => present,
			source => "puppet://files/swift/etc.swift.conf",
			owner => root,
			group => root,
			mode => 0444;
	}

}

class swift::proxy {
	include swift::base
	system_role { "swift:base": description => "This is a swift frontend proxy" }

	package { [ "swift-proxy", "memcached" ]:
		ensure => present;
	}

	file { "/etc/swift/cert.crt":
			ensure => present,
			source => "puppet://private/swift/cert.crt"
			owner => root,
			group => root,
			mode => 0444;
		"/etc/swift/cert.key":
			ensure => present,
			source => "puppet://private/swift/cert.key"
			owner => root,
			group => root,
			mode => 0444;
	}

}

class swift:storage {
	include swift::base
	system_role { "swift::storage": description => "This is a swift backend storage brick" }

	package { 
		[ "swift-account",
		  "swift-container",
		  "swift-object" ]:
		ensure => present;
	}

}


