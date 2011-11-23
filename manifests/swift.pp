# swift.pp

class swift::base {

	# FIXME: split these iptables rules apart into common, proxy, and
	# storage so storage nodes aren't listening on http, etc.
	# load iptables rules to allow http-alt, memcached, rsync, swift protocols, ssh, and all ICMP traffic.
	include swift::iptables

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

# set up iptables rules to protect these hosts
class swift::iptables-purges {
	require "iptables::tables"
	# The deny_all rule must always be purged, otherwise ACCEPTs can be placed below it
	iptables_purge_service{ "swift_common_default_deny": service => "all" }
	# When removing or modifying a rule, place the old rule here, otherwise it won't
	# be purged, and will stay in the iptables forever
}
class swift::iptables-accepts {
	require "swift::iptables-purges"
	# Rememeber to place modified or removed rules into purges!
	# common services for all hosts
	iptables_add_service{ "swift_common_ssh": service => "ssh", source => "208.80.152.0/22", jump => "ACCEPT" }
	iptables_add_service{ "swift_common_icmp": service => "icmp", jump => "ACCEPT" }
	# swift specific services
	iptables_add_service{ "swift_common_account": service => "swift_account", source => "208.80.152.0/22", jump => "ACCEPT" }
	iptables_add_service{ "swift_common_container": service => "swift_container", source => "208.80.152.0/22", jump => "ACCEPT" }
	iptables_add_service{ "swift_common_object": service => "swift_object", source => "208.80.152.0/22", jump => "ACCEPT" }
	iptables_add_service{ "swift_storage_rsyncd": service => "rsyncd", source => "208.80.152.0/22", jump => "ACCEPT" }
}
	iptables_add_service{ "swift_proxy_http_alt": service => "http-alt", jump => "ACCEPT" }
	iptables_add_service{ "swift_proxy_memcached": service => "memcached-standard", source => "208.80.152.0/22", jump => "ACCEPT" }
}
class swift::iptables-drops {
	require "swift::iptables-accepts"
	# Rememeber to place modified or removed rules into purges!
	iptables_add_service{ "swift_common_default_deny": service => "all", jump => "DROP" }
}
class swift::iptables  {
	# We use the following requirement chain:
	# iptables -> iptables::drops -> iptables::accepts -> iptables::purges
	#
	# This ensures proper ordering of the rules
	require "swift::iptables-drops"
	# This exec should always occur last in the requirement chain.
	## creating iptables rules but not enabling them to test.
	#iptables_add_exec{ "swift: service => "swift" }
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
		"/usr/local/lib/python2.6/dist-packages/wmf/__init__.py":
			ensure => present,
			source => "puppet:///files/swift/SwiftMedia/wmf/__init__.py",
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


