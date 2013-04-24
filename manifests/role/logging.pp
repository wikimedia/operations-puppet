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

class role::logging::webstatscollector {
	# datasets account is needed so that snapshot1
	# can rsync webstats dumps to dataset2 (dumps.wikimedia.org).
	include accounts::datasets

	# webstatscollector package creates this directory.
	# webstats-collector process writes dump files here.
	$webstats_dumps_directory = '/a/webstats/dumps'

	package { 'webstatscollector': ensure => installed }
	service { 'webstats-collector':
		ensure     => running,
		hasstatus  => false,
		hasrestart => true,
		require    => Package['webstatscollector'],
	}

	# Gzip pagecounts files hourly.
	# This originally lived as an unpuppetized
	# cron on locke that ran /a/webstats/scripts/tar.
	cron { 'webstats-dumps-gzip':
		command => "/bin/gzip ${webstats_dumps_directory}/pagecounts-????????-?????? 2> /dev/null",
		minute  => 2,
		user    => 'nobody',
		require => Service['webstats-collector'],
	}

	# Delete webstats dumps that are older than 10 days daily.
	# This originally lived as an unpuppetized
	# cron on locke that ran /a/webstats/scripts/purge.
	cron { 'webstats-dumps-delete':
		command => "/usr/bin/find ${webstats_dumps_directory} -maxdepth 1 -type f -mtime +10 -delete",
		minute  => 28,
		hour    => 1,
		user    => 'nobody',
		require => Service['webstats-collector'],
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
		owner   => 'udp2log',
		group   => 'file_mover',
		require => Class['accounts::file_mover'],
	}
	file { "$fundraising_log_directory/logs":
		ensure  => directory,
		mode    => 2775,  # make sure setgid bit is set.
		owner   => 'udp2log',
		group   => 'file_mover',
		require => Class['accounts::file_mover'],
	}

	# gadolinium runs Domas' webstatscollector.
	# udp2log runs the 'filter' binary from this
	# package, which sends logs over to the 'collector'
	# service, which writes dump files in /a/webstats/dumps.
	include role::logging::webstatscollector

	# webrequest udp2log instance
	misc::udp2log::instance { 'gadolinium':
		# gadolinium consumes from the multicast stream relay (from oxygen)
		multicast     => true,
		log_directory => $webrequest_log_directory,
		require       => Class['role::logging::webstatscollector'],
	}
}


# emery is a generic webrequests udp2log host.
class role::logging::udp2log::emery inherits role::logging::udp2log {
	# udp2log::instance will ensure this is created
	$webrequest_log_directory    = "$log_directory/webrequest"

	misc::udp2log::instance { 'emery': 
		log_directory => $webrequest_log_directory,
	}
}

# EventLogging collector
class role::logging::eventlogging {
	system_role { "misc::log-collector":
		description => 'EventLogging log collector',
	}

	class{ "eventlogging":
		archive_destinations => [ "stat1.wikimedia.org" ],
	}
}
