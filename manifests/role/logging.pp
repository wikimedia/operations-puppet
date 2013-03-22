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

	$log_directory               = '/a/log'
	$webrequest_log_directory    = "$log_directory/webrequest"
	$webrequest_filter_directory = "$webrequest_log_directory/bin"

	file { $log_directory:
		ensure => 'directory',
	}
	file { $webrequest_log_directory:
		ensure => directory,
		mode   => 0755,
		owner  => 'udp2log',
		group  => 'udp2log',
	}

	# install custom filters here
	file { $webrequest_filter_directory:
		ensure => directory,
		mode   => 0755,
		owner  => 'udp2log',
		group  => 'udp2log',
	}

	# Set up an rsync daemon module for udp2log logrotated
	# archives.  This allows stat1 to copy logs from the
	# logrotated archive directory
	class { 'misc::udp2log::rsyncd':
		path    => $log_directory,
		require => File[$log_directory],
	}
}


# gadolinium udp2log instance(s).
# gadolinum hosts the 'gadolinium' udp2log instance,
# as well as the nginx udp2log instance.
class role::logging::udp2log::gadolinium inherits role::logging::udp2log {
	# need file_mover account for fundraising logs
	include accounts::file_mover
	# gadolinium keeps fundraising logs in a subdir
	$fundraising_log_directory = "$log_directory/fundraising"

	file { "$webrequest_filter_directory/vu.awk":
		ensure => 'file',
		source => 'puppet:///files/udp2log/vu.awk',
		mode   => 0755,
		owner  => 'udp2log',
		group  => 'udp2log',
	}
	file { "$webrequest_filter_directory/minnesota.awk":
		ensure => 'file',
		source => 'puppet:///files/udp2log/minnesota.awk',
		mode   => 0755,
		owner  => 'udp2log',
		group  => 'udp2log',
	}

	file { "$fundraising_log_directory":
		ensure => directory,
		mode   => 0775,
		owner  => 'udp2log',
		group  => 'file_mover',
	}
	file { "$fundraising_log_directory/logs":
		ensure => directory,
		mode   => 0775,
		owner  => 'udp2log',
		group  => 'file_mover',
	}

	# Don't forget:
	# - 5xx-filter from udplog repository
	# - webstatscollector filter and collector
	# These are not puppetized :( :(

	# webrequest udp2log instance
	misc::udp2log::instance { 'gadolinium':
		# gadolinium consumes from the multicast stream relay (from oxygen)
		multicast     => true,
		log_directory => $webrequest_log_directory,
		require       => File[$webrequest_log_directory],
	}

	# nginx machines are configured to log to
	# gadolinium on port 8421.
	# Since nginx logs are webrequest logs, save
	# them in the same directory.
	udp2log::instance { 'nginx':
		port          => '8421',
		log_directory => $webrequest_log_directory,
		require       => File[$webrequest_log_directory],
		# the gadolinium udp2log instance already
		# log rotates for $webrequest_log_directory
		log_rotate    => false,
	}
}
