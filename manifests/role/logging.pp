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
		misc::geoip
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

	cron { "mw-log-cleanup":
		command => "/usr/local/bin/mw-log-cleanup",
		user => root,
		hour => 2,
		minute => 0
	}

	file { "/usr/local/bin/mw-log-cleanup":
		source => "puppet:///files/misc/scripts/mw-log-cleanup",
		mode => '0555'
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

	file { $log_directory:
		ensure => 'directory',
	}

	# Set up an rsync daemon module for udp2log logrotated
	# archives.  This allows stat1 to copy logs from the
	# logrotated archive directory
	class { 'misc::udp2log::rsyncd':
		path    => $log_directory,
		require => File[$log_directory],
	}
}

# nginx machines are configured to log to port 8421.
class role::logging::udp2log::nginx inherits role::logging::udp2log {
	$nginx_log_directory = "$log_directory/nginx"

	misc::udp2log::instance { 'nginx':
		port                => '8421',
		log_directory       => $nginx_log_directory,
		# don't monitor packet loss,
		# we aren't keeping packet loss log, 
		# and nginx sequence numbers are messed up anyway.
		monitor_packet_loss => false
	}
}


# gadolinium udp2log instance(s).
# gadolinium hosts the 'gadolinium' udp2log instance,
# as well as the nginx udp2log instance.
class role::logging::udp2log::gadolinium inherits role::logging::udp2log {
	# need file_mover account for fundraising logs
	include accounts::file_mover

	# udp2log::instance will ensure this is created
	$webrequest_log_directory    = "$log_directory/webrequest"

	# install custom filters here
	$webrequest_filter_directory = "$webrequest_log_directory/bin"
	file { $webrequest_filter_directory:
		ensure => directory,
		mode   => 0755,
		owner  => 'udp2log',
		group  => 'udp2log',
	}

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
		ensure  => directory,
		mode    => 0775,
		owner   => 'file_mover',
		group   => 'udp2log',
		require => Class['accounts::file_mover'],
	}
	file { "$fundraising_log_directory/logs":
		ensure  => directory,
		mode    => 0775,
		owner   => 'file_mover',
		group   => 'udp2log',
		require => Class['accounts::file_mover'],
	}

	# gadolinium runs Domas' webstatscollector
	package { 'webstatscollector': ensure => installed }
	service { 'webstats-collector':
		ensure     => running,
		hasstatus  => false,
		hasrestart => true,
		require    => Package['webstatscollector'],
	}

	# webrequest udp2log instance
	misc::udp2log::instance { 'gadolinium':
		# gadolinium consumes from the multicast stream relay (from oxygen)
		multicast     => true,
		log_directory => $webrequest_log_directory,
		require       => Package['webstatscollector'],
	}
	
}
