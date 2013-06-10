# swift.pp

# $hash_path_suffix is a unique string per cluster used to hash partitions
# $cluster_name is a string defining the cluster, eg eqiad-test or pmtpa-prod.
#               It is used to find the ring files in the puppet files
class swift::base($hash_path_suffix, $cluster_name) {

	# include tcp settings
	include swift::sysctl::tcp-improvements
	include generic::sysctl::high-http-performance

	# this is on purpose not a >=. the cloud archive only exists for
	# precise right now, and will perhaps exist for the next LTS, but
	# surely not for the intermediate releases.
	if ($::lsbdistcodename == 'precise') {
		apt::repository { 'ubuntucloud':
			uri        => 'http://ubuntu-cloud.archive.canonical.com/ubuntu',
			dist       => 'precise-updates/folsom',
			components => 'main',
			keyfile    => 'puppet:///files/misc/ubuntu-cloud.key',
			before     => Package['swift'],
		}
	}

	package { [
		'swift',
		'swift-doc',
		'python-swift',
		'python-swiftclient',
		'python-ss-statsd',
		]:
		ensure => present;
	}

	File {
		owner => "swift",
		group => "swift",
		mode => 0440
	}
	file {
		"/etc/swift":
			require => Package[swift],
			ensure => directory,
			recurse => true;
		"/etc/swift/swift.conf":
			require => Package[swift],
			ensure => present,
			content => template("swift/etc.swift.conf.erb");
		"/etc/swift/account.builder":
			ensure => present,
			source => "puppet:///volatile/swift/${cluster_name}/account.builder";
		"/etc/swift/account.ring.gz":
			ensure => present,
			source => "puppet:///volatile/swift/${cluster_name}/account.ring.gz";
		"/etc/swift/container.builder":
			ensure => present,
			source => "puppet:///volatile/swift/${cluster_name}/container.builder";
		"/etc/swift/container.ring.gz":
			ensure => present,
			source => "puppet:///volatile/swift/${cluster_name}/container.ring.gz";
		"/etc/swift/object.builder":
			ensure => present,
			source => "puppet:///volatile/swift/${cluster_name}/object.builder";
		"/etc/swift/object.ring.gz":
			ensure => present,
			source => "puppet:///volatile/swift/${cluster_name}/object.ring.gz";
	}
	include ganglia::logtailer
	file { "/usr/share/ganglia-logtailer/SwiftHTTPLogtailer.py":
		owner => root,
		group => root,
		mode => 0444,
		source => "puppet:///files/swift/SwiftHTTPLogtailer.py",
		require => Package['ganglia-logtailer']
	}
	cron { swift-proxy-ganglia:
		command => "/usr/sbin/ganglia-logtailer --classname SwiftHTTPLogtailer --log_file /var/log/syslog --mode cron > /dev/null 2>&1",
		user => root,
		minute => '*',
		ensure => present
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
	iptables_add_service{ "swift_common_ssh_all": service => "ssh", jump => "ACCEPT" }
	iptables_add_service{ "swift_ntp_udp": service => "ntp_udp", source => "208.80.152.0/22", jump => "ACCEPT" }
	iptables_add_service{ "swift_nrpe": service => "nrpe", source => "208.80.152.0/22", jump => "ACCEPT" }
	iptables_add_service{ "swift_gmond_tcp": service => "gmond_tcp", source => "208.80.152.0/22", jump => "ACCEPT" }
	iptables_add_service{ "swift_gmond_udp": service => "gmond_udp", destination => "239.192.0.0/16", jump => "ACCEPT" }
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
		mode => 0444,
		notify => Exec["/sbin/start procps"],
		source => "puppet:///files/swift/60-swift-performance.conf.sysctl",
		ensure => $ensure
	}
}
class swift::proxy {
	Class[swift::proxy::config] -> Class[swift::proxy]

	system_role { "swift:base": description => "swift frontend proxy" }

	include swift::proxy::monitoring

	realize File["/etc/swift/proxy-server.conf"]

	package { ['swift-proxy', 'python-swauth']:
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
	if ($::lsbdistcodename == "precise") {
		file { "/usr/local/lib/python2.7/dist-packages/wmf/":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/swift/SwiftMedia/wmf/",
			recurse => remote;
		}
	}
	else {
		file { "/usr/local/lib/python2.6/dist-packages/wmf/":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/swift/SwiftMedia/wmf/",
			recurse => remote;
		}
	}
}

class swift::proxy::monitoring {

	monitor_service { "swift http": description => "Swift HTTP", check_command => "check_http_swift!80" }

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
	$rewrite_thumb_server,
	$shard_container_list,
	$backend_url_format ) {

	Class[swift::base] -> Class[swift::proxy::config]

	# Virtual resource
	@file { "/etc/swift/proxy-server.conf":
		owner => swift,
		group => swift,
		mode => 0440,
		content => template("swift/proxy-server.conf.erb")
	}

}

# swift out-of-band file cleaner.
# looks through all the objects in swift for corrupted thumbnail images.
# purges them from swift, ms5, and the squids.
# it is not necessary to run this on a swift host.
# current setup is running 2 copies of this on iron
## one copy that checks all recent stuff relatively quickly
## one copy that continuously checks all objects but slowly.
#
##  NOTE  this class is now ensuring the cron is absent.
##        Since ms5 is now out of rotation and mediawiki is writing
##        directly to sift, we don't need it anymore.
class swift::cleaner {
	define swiftcleanercron(
		$name,
		$swiftcleaner_basedir,
		$config_file_location,
		$num_manager_threads,
		$num_threads,
		$delay_time,
		$rewrite_user,
		$rewrite_password,
		$statedir,
		$scrubstate,
		$save_deletes ) {
		# pull in the config file specific to this cluster
		file { "$swiftcleaner_basedir/swiftcleaner-$name.conf":
			owner => root,
			group => root,
			mode => 0440,
			content => template("swift/swiftcleaner.conf")
		}
		# make sure the statedir for the cleaner exists
		file { "$statedir":
			owner => root,
			group => root,
			mode => 0644,
			ensure => directory;
		}
		# set up the cronjob itself
		cron { "swiftcleaner-$name":
			command => "$swiftcleaner_basedir/swiftcleanermanager -c $swiftcleaner_basedir/swiftcleaner-$name.conf -A /tmp/swiftcleaner-${name}-\$(date +\%Y\%m\%dT\%H\%M\%S) -p /tmp/swiftcleaner-$name.pid >> /tmp/swiftcleaner-${name}-\$(date +\%Y\%m\%dT\%H\%M\%S).log",
			user => root,
			minute => 1,
			hour => 22, #the beginning of the daily trough
			ensure => absent
		}
	}
	# install basic app
	package { ["python-eventlet", "php5-cli"]:
		ensure => present;
	}
	$swiftcleaner_basedir = "/opt/swiftcleaner"
	file{ "$swiftcleaner_basedir":
		source => "puppet:///files/swift/swiftcleaner",
		owner => "root",
		group => "root",
		recurse => remote;
	}
	include passwords::swift::pmtpa-prod
	# run the incremental scan at a reasonable rate - it should take 1-4 hours to run or so.
	swiftcleanercron { "swiftcleaner-incremental" :
		name => "incremental",
		swiftcleaner_basedir => $swiftcleaner_basedir,
		config_file_location => "swiftcleaner-incremental.conf",
		num_manager_threads => 7,
		num_threads => 10,
		delay_time => 0.1,
		rewrite_user => "mw:thumb",
		rewrite_password => $passwords::swift::pmtpa-prod::rewrite_password,
		statedir => "/var/lib/swiftcleaner-incremental",
		scrubstate => "False",
		save_deletes => "True"
		}
	# run the full scan slower
	swiftcleanercron { "swiftcleaner-full" :
		name => "full",
		swiftcleaner_basedir => $swiftcleaner_basedir,
		config_file_location => "swiftcleaner-full.conf",
		num_manager_threads => 5,
		num_threads => 5,
		delay_time => 0.1,
		rewrite_user => "mw:thumb",
		rewrite_password => $passwords::swift::pmtpa-prod::rewrite_password,
		statedir => "/var/lib/swiftcleaner-full",
		scrubstate => "True",
		save_deletes => "True"
		}
}

class swift::storage {
	Class[swift::base] -> Class[swift::storage]

	system_role { "swift::storage": description => "swift backend storage brick" }

	class packages {
		package {
			[ "swift-account",
			  "swift-container",
			  "swift-object" ]:
			ensure => present;
		}
	}

	class config {
		require swift::storage::packages

		class { "generic::rsyncd": config => "swift" }

		# set up swift specific configs
		File { owner => swift, group => swift, mode => 0440 }
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
			mode => 0751, # the 1 is to allow nagios to read the drives for check_disk
			ensure => directory;
		}
	}

	class service {
		require swift::storage::config

		Service { ensure => running }
		service {
			[ swift-account, swift-account-auditor, swift-account-reaper, swift-account-replicator ]:
				subscribe => File["/etc/swift/account-server.conf"];
			[ swift-container, swift-container-auditor, swift-container-replicator, swift-container-updater ]:
				subscribe => File["/etc/swift/container-server.conf"];
			[ swift-object, swift-object-auditor, swift-object-replicator, swift-object-updater ]:
				subscribe => File["/etc/swift/object-server.conf"];
		}
	}

	class monitoring {
		require swift::storage::service
		$nagios_group = "swift"
		monitor_service { "swift-account-auditor": description => "swift-account-auditor", check_command => "nrpe_check_swift_account_auditor" }
		monitor_service { "swift-account-reaper": description => "swift-account-reaper", check_command => "nrpe_check_swift_account_reaper" }
		monitor_service { "swift-account-replicator": description => "swift-account-replicator", check_command => "nrpe_check_swift_account_replicator" }
		monitor_service { "swift-account-server": description => "swift-account-server", check_command => "nrpe_check_swift_account_server" }
		monitor_service { "swift-container-auditor": description => "swift-container-auditor", check_command => "nrpe_check_swift_container_auditor" }
		monitor_service { "swift-container-replicator": description => "swift-container-replicator", check_command => "nrpe_check_swift_container_replicator" }
		monitor_service { "swift-container-server": description => "swift-container-server", check_command => "nrpe_check_swift_container_server" }
		monitor_service { "swift-container-updater": description => "swift-container-updater", check_command => "nrpe_check_swift_container_updater" }
		monitor_service { "swift-object-auditor": description => "swift-object-auditor", check_command => "nrpe_check_swift_object_auditor" }
		monitor_service { "swift-object-replicator": description => "swift-object-replicator", check_command => "nrpe_check_swift_object_replicator" }
		monitor_service { "swift-object-server": description => "swift-object-server", check_command => "nrpe_check_swift_object_server" }
		monitor_service { "swift-object-updater": description => "swift-object-updater", check_command => "nrpe_check_swift_object_updater" }
	}

	# this class installs swift-drive-audit as a cronjob; it checks the disks every 60 minutes
	# and unmounts failed disks. It logs its actions to /var/log/syslog.
	class driveaudit {
		require swift::storage::service
		# this file comes from the python-swift package but there are local improvements
		# that are not yet merged upstream.
		file { "/usr/bin/swift-drive-audit":
			owner => root,
			group => root,
			mode => 755,
			source => "puppet:///files/swift/usr.bin.swift-drive-audit"
		}
		file { "/etc/swift/swift-drive-audit.conf":
			owner => root,
			group => root,
			mode => 0440,
			source => "puppet:///files/swift/etc.swift.swift-drive-audit.conf"
		}
		cron { "swift-drive-audit":
			command => "/usr/bin/swift-drive-audit /etc/swift/swift-drive-audit.conf",
			user => root,
			minute => 1,
			ensure => present
		}
	}

	include packages, config, service, driveaudit
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

	if ($title =~ /^\/dev\/([hvs]d[a-z]+|md[0-9]+)$/) {
		$dev = "${title}${partition_nr}"
		$dev_suffix = regsubst($dev, '^\/dev\/(.*)$', '\1')
		exec { "swift partitioning $title":
			path => "/usr/bin:/bin:/usr/sbin:/sbin",
			command => "parted -s -a optimal ${title} mklabel gpt mkpart swift-${dev_suffix} 0% 100% && mkfs -t xfs -i size=512 -L swift-${dev_suffix} ${dev}",
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


# Definition: swift::label_filesystem
#
# labels an XFS filesystem on a block device ($title) as
# swift-xxxx (example: swift-sdm3), only if the device is
# unmounted, has an xfs filesystem on it, and the filesystem
# does not already have a pre-existing swift label
# (so we don't accidentally relabel devices that show up with
# a changed device id)
#
# this would typically be used for devices partitioned and
# with xfs filesystems created at install time but no labels
#
# Parameters:
#	- $title:
#		The device to label (e.g. /dev/sdc1)
define swift::label_filesystem() {
	$device = $title
	$dev_suffix = regsubst($device, '^\/dev\/(.*)$', '\1')

	$label = "swift-${dev_suffix}"
	exec { "/usr/sbin/xfs_admin -L $label $device":
		onlyif => "/usr/bin/test $(/bin/mount | /bin/grep $device | /usr/bin/wc -l) -eq 0 && /usr/bin/test $(/usr/sbin/grub-probe -t fs -d  $device) = 'xfs' && /usr/bin/test $(/usr/sbin/xfs_admin -l $device | /bin/grep swift | /usr/bin/wc -l) -eq 0"
	}
}


# installs the swift cli for interacting with remote swift installations.
class swift::utilities {
	package { "swift":
		ensure => present;
	}
}
