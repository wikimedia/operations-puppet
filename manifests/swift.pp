# swift.pp

# TODO: document parameters
class swift::base($hash_path_suffix) {

	# FIXME: split these iptables rules apart into common, proxy, and
	# storage so storage nodes aren't listening on http, etc.
	# load iptables rules to allow http-alt, memcached, rsync, swift protocols, ssh, and all ICMP traffic.
	include swift::iptables

	# include tcp settings
	include swift::sysctl::tcp-improvements
	include generic::sysctl::high-http-performance

	package { "swift":
		ensure => present;
	}

	file {
		"/etc/swift":
			require => Package[swift],
			ensure => directory,
			recurse => true,
			owner => swift,
			group => swift,
			mode => 0444;
		"/etc/swift/swift.conf":
			require => Package[swift],
			ensure => present,
			content => template("swift/etc.swift.conf.erb"),
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
	iptables_add_rule{ "swift_common_established_tcp": table => "filter", chain => "INPUT", protocol => "tcp", accept_established => "true", jump => "ACCEPT" }
	iptables_add_rule{ "swift_common_established_udp": table => "filter", chain => "INPUT", protocol => "udp", accept_established => "true", jump => "ACCEPT" }
	iptables_add_service{ "swift_accept_all_private": service => "all", source => "10.0.0.0/8", jump => "ACCEPT" }
	iptables_add_service{ "swift_accept_all_localhost": service => "all", source => "127.0.0.0/8", jump => "ACCEPT" }
	iptables_add_service{ "swift_common_ssh": service => "ssh", source => "208.80.152.0/22", jump => "ACCEPT" }
	iptables_add_service{ "swift_ntp_udp": service => "ntp_udp", source => "208.80.152.0/22", jump => "ACCEPT" }
	iptables_add_service{ "swift_gmond_tcp": service => "gmond_tcp", source => "208.80.152.0/22", jump => "ACCEPT" }
	iptables_add_service{ "swift_gmond_udp": service => "gmond_udp", destination => "239.192.0.0/24", jump => "ACCEPT" }
	iptables_add_service{ "swift_common_igmp": service => "igmp", jump => "ACCEPT" }
	iptables_add_service{ "swift_common_icmp": service => "icmp", jump => "ACCEPT" }
	# swift specific services
	iptables_add_service{ "swift_common_account": service => "swift_account", source => "208.80.152.0/22", jump => "ACCEPT" }
	iptables_add_service{ "swift_common_container": service => "swift_container", source => "208.80.152.0/22", jump => "ACCEPT" }
	iptables_add_service{ "swift_common_object": service => "swift_object", source => "208.80.152.0/22", jump => "ACCEPT" }
	iptables_add_service{ "swift_storage_rsyncd_tcp": service => "rsyncd_tcp", source => "208.80.152.0/22", jump => "ACCEPT" }
	iptables_add_service{ "swift_storage_rsyncd_udp": service => "rsyncd_udp", source => "208.80.152.0/22", jump => "ACCEPT" }
	iptables_add_service{ "swift_proxy_http_alt": service => "http-alt", jump => "ACCEPT" }
	iptables_add_service{ "swift_proxy_http": service => "http", jump => "ACCEPT" }
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
	iptables_add_exec{ "swift": service => "swift" }
}
class swift::sysctl::tcp-improvements($ensure="present") {
	file { swift-performance-sysctl:
		name => "/etc/sysctl.d/60-swift-performance.conf",
		owner => root,
		group => root,
		mode => 444,
		notify => Exec["/sbin/start procps"],
		source => "puppet:///files/swift/60-swift-performance.conf.sysctl",
		ensure => $ensure
	}
}
class swift::proxy {
	Class[swift::proxy::config] -> Class[swift::proxy]

	system_role { "swift:base": description => "swift frontend proxy" }

	realize File["/etc/swift/proxy-server.conf"]

	package { ["swift-proxy", "python-swauth"]:
		ensure => present;
	}

	# we're using http for now; no need for a cert.
	#install_cert { "swift": privatekey => true }

	# use a generic (parameterized) memcached class
	class { "memcached": memcached_size => '128', memcached_port => '11211' }

	# pull in the SwiftMedia python bits
	# note that though these are in puppet, svn is the canonical store;
	# any changes here hsould flow back there, and those files should
	# be checked every now and again for more recent versions.
	# http://svn.wikimedia.org/viewvc/mediawiki/trunk/extensions/SwiftMedia/
	file { "/usr/local/lib/python2.6/dist-packages/wmf/":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/swift/SwiftMedia/wmf/",
			recurse => remote;
	}
}

# TODO: document parameters

# Class: swift::proxy::config
#
# This class configures a Swift Proxy.
#
# Only put virtual resources in this class, as it's included
# on non-proxy swift nodes as well.
#
# Parameters:
class swift::proxy::config(
	$bind_port="8080",
	$proxy_address,
	$memcached_servers,
	$num_workers,
	$super_admin_key,
	$rewrite_account,
	$rewrite_url,
	$rewrite_user,
	$rewrite_password,
	$rewrite_thumb_server,
	$shard_containers,
	$shard_container_list ) {

	Class[swift::base] -> Class[swift::proxy::config]

	# Virtual resource
	@file { "/etc/swift/proxy-server.conf":
		owner => swift,
		group => swift,
		mode => 0444,
		content => template("swift/proxy-server.conf.erb")
	}

	include ganglia::logtailer
	file { "/usr/share/ganglia-logtailer/SwiftProxyLogtailer.py":
		owner => root,
		group => root,
		mode => 0444,
		source => "puppet:///files/swift/SwiftProxyLogtailer.py",
		require => Package['ganglia-logtailer']
	}
	cron { swift-proxy-ganglia:
		command => "ganglia-logtailer --classname SwiftProxyLogtailer --log_file /var/log/system.log --mode cron",
		user => root,
		minute => '*/5',
		ensure => present
	}
}

class swift::storage {
	Class[swift::base] -> Class[swift::storage]

	system_role { "swift::storage": description => "swift backend storage brick" }

	package { 
		[ "swift-account",
		  "swift-container",
		  "swift-object" ]:
		ensure => present;
	}

	class { "generic::rsyncd": config => "swift" }

	# set up swift specific configs
	File { owner => swift, group => swift, mode => 0444 }
	file {
		"/etc/swift/account-server.conf":
			content => template("swift/etc.swift.account-server.conf.erb");
		"/etc/swift/container-server.conf":
			content => template("swift/etc.swift.container-server.conf.erb");
		"/etc/swift/object-server.conf":
			content => template("swift/etc.swift.object-server.conf.erb");
	}

	file { "/srv/swift-storage":
		require => Package[swift],
		owner => swift,
		group => swift,
		mode => 0750,
		ensure => directory;
	}

	service {
		[ swift-account, swift-account-auditor, swift-account-reaper, swift-account-replicator ]:
			subscribe => File["/etc/swift/account-server.conf"];
		[ swift-container, swift-container-auditor, swift-container-replicator, swift-container-updater ]:
			subscribe => File["/etc/swift/container-server.conf"];
		[ swift-object, swift-object-auditor, swift-object-replicator, swift-object-updater ]:
			subscribe => File["/etc/swift/object-server.conf"];
	}

}

# Definition: swift::create_filesystem
#
# Creates a new partition table on a device, and
# creates a partition and file system for Swift
#
# Parameters:
#	- $title:
#		The device to partition
define swift::create_filesystem($partition_nr="1") {
	require base::platform

	if ($title =~ /^\/dev\/([hvs]d[a-z]+|md[0-9]+)$/) and ! ($title in $base::platform::startup_drives) {
		$dev = "${title}${partition_nr}"
		$dev_suffix = regsubst($dev, '^\/dev\/(.*)$', '\1')
		exec { "swift partitioning $title":
			path => "/usr/bin:/bin:/usr/sbin:/sbin",
			command => "parted -s -a optimal ${title} mklabel gpt mkpart swift-${dev_suffix} 0% 100% && mkfs -t xfs -L swift-${dev_suffix} ${dev}",
			creates => $dev
		}

		swift::mount_filesystem { "$dev": require => Exec["swift partitioning $title"] }
	}
}



# Definition: swift::mount_filesystem
#
# Mounts a block device ($title) under /srv/swift-storage/$devname
# as XFS with the appropriate file system options, and updates fstab
#
# Parameters:
#	- $title:
#		The device to mount (e.g. /dev/sdc1)
define swift::mount_filesystem() {
	$dev = $title
	$dev_suffix = regsubst($dev, '^\/dev\/(.*)$', '\1')
	$mountpath = "/srv/swift-storage/${dev_suffix}"

	# Make sure the mountpoint exists...
	# This can't be a file resource, as it would become a duplicate.
	exec { "mkdir $mountpath":
		require => File["/srv/swift-storage"],
		path => "/usr/bin:/bin",
		creates => $mountpath
	}

	# ...mount the filesystem by label...
	mount { $mountpath:
		device => "LABEL=swift-${dev_suffix}",
		name => $mountpath,
		ensure => mounted,
		fstype => "xfs",
		options => "noatime,nodiratime,nobarrier,logbufs=8",
		atboot => true,
		remounts => true
	}

	# ...and fix the directory attributes.
	file { "fix attr $mountpath":
		require => Class[swift::base],
		path => $mountpath,
		owner => swift,
		group => swift,
		mode => 0750,
		ensure => directory
	}

	Exec["mkdir $mountpath"] -> Mount[$mountpath] -> File["fix attr $mountpath"]
}

