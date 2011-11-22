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
			source => "puppet:///files/swift/etc.swift.conf",
			owner => swift,
			group => swift,
			mode => 0444;
	}

}

class swift::proxy {
	include swift::base
	system_role { "swift:base": description => "swift frontend proxy" }

	package { "swift-proxy":
		ensure => present;
	}

	# FIXME: use generic install_cert in /etc/ssl if possible
	file { "/etc/swift/cert.crt":
			ensure => present,
			source => "puppet:///private/swift/cert.crt",
			owner => swift,
			group => swift,
			mode => 0444;
		"/etc/swift/cert.key":
			ensure => present,
			source => "puppet:///private/swift/cert.key",
			owner => swift,
			group => swift,
			mode => 0444;
	}

	# TODO: create and/or use a generic (parameterized) memcached class instead
	
	# set up memcached
	package { "memcached":
			ensure => present;
	}
	service { "memcached":
			enable => true,
			ensure => running,
			subscribe => File["/etc/memcached.conf"];
	}
	file { "/etc/memcached.conf":
			ensure => present,
			source => "puppet:///files/swift/memcached.conf",
			owner => root,
			group => root,
			mode => 0444;
	}

	# pull in the SwiftMedia python bits
	# note that though these are in puppet, svn is the canonical store;
	# any changes here hsould flow back there, and those files should
	# be checked every now and again for more recent versions.
	# http://svn.wikimedia.org/viewvc/mediawiki/trunk/extensions/SwiftMedia/
	file { "/usr/local/lib/python2.6/dist-packages/wmf":
			ensure => directory,
			owner => root,
			group => root,
			mode => 0644;
		"/usr/local/lib/python2.6/dist-packages/wmf/client.py":
			ensure => present,
			source => "puppet:///files/swift/SwiftMedia/wmf/client.py",
			owner => root,
			group => root,
			mode => 0444;
		"/usr/local/lib/python2.6/dist-packages/wmf/rewrite.py":
			ensure => present,
			source => "puppet:///files/swift/SwiftMedia/wmf/rewrite.py",
			owner => root,
			group => root,
			mode => 0444;
		"/usr/local/lib/python2.6/dist-packages/wmf/__init.py__":
			ensure => present,
			source => "puppet:///files/swift/SwiftMedia/wmf/__init.py__",
			owner => root,
			group => root,
			mode => 0444;
		"/usr/local/lib/python2.6/dist-packages/wmf/swift.php":
			ensure => present,
			source => "puppet:///files/swift/SwiftMedia/wmf/swift.php",
			owner => root,
			group => root,
			mode => 0444;
	}
}

class swift::proxy::testclusterconf {
	# because I can't figure out how to aggregate a list of all proxy servers
	# within puppet and use that list in a template, I have a different config
	# file for each swift cluster so that they can use their own memcached 
	# instances.
	
	# FIXME: require /etc/swift to exist
	file { "/etc/swift/proxy-server.conf":
			ensure => present,
			source => "puppet:///files/swift/proxy-server.conf-testcluster",
			owner => swift,
			group => swift,
			mode => 0444;
	}
}

class swift::storage {
	include swift::base
	system_role { "swift::storage": description => "swift backend storage brick" }

	package { 
		[ "swift-account",
		  "swift-container",
		  "swift-object" ]:
		ensure => present;
	}

	# FIXME: use the generic rsync class in generic-definitions

	# set up rsync to allow the storage nodes to share data bits around
	package { "rsync":
			ensure => present;
	}
	file { "/etc/rsyncd.conf":
			ensure => present,
			source => "puppet:///files/swift/storage-rsyncd.conf",
			owner => root,
			group => root,
			mode => 0444,
			require => Package['rsync'],
			notify => Service['rsync'];
		"/etc/default/rsync":
			ensure => present,
			source => "puppet:///files/swift/storage-rsyncd.default",
			owner => root,
			group => root,
			mode => 0444,
			require => Package['rsync'],
			notify => Service['rsync'];
	}
	service { "rsync":
			ensure => running,
			enable => true,
	}

	# set up swift specific configs
	file { "/etc/swift/account-server.conf":
			ensure => present,
			source => "puppet:///files/swift/etc.swift.account-server.conf",
			owner => swift,
			group => swift,
			mode => 0444;
		"/etc/swift/container-server.conf":
			ensure => present,
			source => "puppet:///files/swift/etc.swift.container-server.conf",
			owner => swift,
			group => swift,
			mode => 0444;
		"/etc/swift/object-server.conf":
			ensure => present,
			source => "puppet:///files/swift/etc.swift.object-server.conf",
			owner => swift,
			group => swift,
			mode => 0444;
	}

}


