# logging (udp2log) servers

# base node definition from which logging nodes (emery, locke, oxygen, etc)
# inherit. Note that there is no real node named "base_analytics_logging_node".
# This is done as a base node primarily so that we can override the
# $nagios_contact_group variable.
node "base_analytics_logging_node" {

	# include analytics in nagios_contact_group.
	# This is used by class base::monitoring::host for
	# notifications when a host or important service goes down.
	# NOTE:  This cannot be a fully qualified var
	# (i.e. $base::nagios_contact_group) because puppet does not
	# allow setting variables in other namespaces.  I could
	# parameterize class base AND class stanrdard and pass
	# the var down the chain, but that seems like too much
	# modification for just this.  Instead this overrides
	# the default contact_group of 'admins' set in class base.
	$nagios_contact_group = "admins,analytics"

	include
		standard,
		role::logging
}

class role::logging
{
	system_role { "role::logging": description => "log collector" }

	# default gid
	$gid=500

	include
		groups::wikidev,
		admins::restricted,
		nrpe,
		geoip
}

# mediawiki udp2log instance.  Does not use monitoring.
class role::logging::mediawiki($monitor = true, $log_directory = '/home/wikipedia/logs' ) {
	system_role { "role::logging:mediawiki": description => "MediaWiki log collector" }

	class { "misc::udp2log": monitor => $monitor }
	include misc::udp2log::utilities,
		misc::udp2log::iptables

	misc::udp2log::instance { "mw":
		log_directory	=>	$log_directory,
		monitor_log_age	=>	false,
		monitor_processes	=>	false,
		monitor_packet_loss	=>	false,
	}
}

class role::beta::logging::mediawiki {

	class { 'role::logging::mediawiki':
		log_directory => '/data/project/logs';
	}

	# Shortcut
	file { '/home/wikipedia/logs':
		ensure => 'link',
		target => '/data/project/logs';
	}
}



# udp2log base role class
class role::logging::udp2log {
	include misc::udp2log,
		misc::udp2log::utilities
}

# gadolinium udp2log instance(s)
class role::logging::udp2log::gadolinum inherits role::logging::udp2log {
	file { '/a/log':
		ensure => 'directory',
	}
	$log_directory = '/a/log/webrequest'
	


	# install custom filters
	file { "$log_directory/bin":
		ensure => directory,
		mode   => 0755,
		owner  => 'udp2log',
		group  => 'udp2log',
	}
	file { "$log_directory/bin/vu.awk":
		ensure => 'file',
		source => 'puppet:///files/udp2log/vu.awk',
		mode   => 0755,
		owner  => 'udp2log',
		group  => 'udp2log',
	}
	file { "$log_directory/bin/minnesota.awk":
		ensure => 'file',
		source => 'puppet:///files/udp2log/minnesota.awk',
		mode   => 0755,
		owner  => 'udp2log',
		group  => 'udp2log',
	}
	# Don't forget:
	# - 5xx-filter from udplog repository
	# - webstatscollector filter and collector
	# These are not puppetized :( :(

	# webrequest udp2log instance
	misc::udp2log::instance { 'gadolinium':
		log_directory => $log_directory,
		require       => File['/a/log'],
	}

	# Set up an rsync daemon module for udp2log logrotated
	# archives.  This allows stat1 to copy logs from the
	# logrotated archive directory
	class { 'misc::udp2log::rsyncd':
		path    => $log_directory,
		require => Misc::Udp2log::Instance['gadolinium'],
	}
}
