@monitor_group { "fundraising_eqiad": description => "fundraising eqiad" }
@monitor_group { "fundraising_ptmpa": description => "fundraising pmtpa" }

class role::fundraising::messaging {
	$cluster = "fundraising"
	$nagios_group = "${cluster}_${::site}"
	include standard,
		groups::wikidev,
		accounts::khorn
}


class role::fundraising::logger {
	$cluster = "fundraising"
	$nagios_group = "${cluster}_${::site}"
	include standard,
		groups::wikidev,
		accounts::khorn,
		accounts::pgehres
}


class role::fundraising::civicrm {
	# variables used in fundraising exim template
	$exim_signs_dkim = "true"
	$exim_bounce_collector = "true"
	
	$cluster = "fundraising"
	$nagios_group = "${cluster}_${::site}"

	install_certificate{ "star.wikimedia.org": }

	sudo_user { [ "khorn" ]: privileges => ['ALL = NOPASSWD: ALL'] }

	$gid = 500
	include base,
		ganglia,
		ntp::client,
		nrpe,
		admins::roots,
		accounts::khorn,
		accounts::mhernandez,
		accounts::mwalker,
		accounts::pgehres,
		accounts::pcoombe,
		accounts::rfaulk,
		accounts::zexley,
		backup::client,
		misc::fundraising,
		misc::fundraising::mail,
		misc::fundraising::backup::offhost,
		misc::fundraising::backup::archive

	if $hostname == "aluminium" {
		include misc::jenkins,
			misc::fundraising::jenkins_maintenance
	}

	cron {
		'offhost_backups':
			user => root,
			minute => '5',
			hour => '0',
			command => '/usr/local/bin/offhost_backups',
			ensure => present,
	}

	monitor_service { "smtp": description => "Exim SMTP", check_command => "check_smtp" }
	monitor_service { "http": description => "HTTP", check_command => "check_http" }
}


class role::fundraising::database {
	$crit = $master
	$cluster = "fundraising"
	$db_cluster = "fundraisingdb"
	$nagios_group = "${cluster}_${::site}"

	system_role { "role::fundraising::database": description => "Fundraising Database (${mysql_role})" }

	include standard,
		mysql,
		mysql::mysqluser,
		mysql::datadirs,
		mysql::packages,
		mysql::conf

	monitor_service {
		"mysqld":
			description => "mysqld processes",
			check_command => "nrpe_check_mysqld",
			critical => $crit;
	}
}


class role::fundraising::database::master {
	$mysql_role = "master"
	$writable = true
	include role::fundraising::database
}


class role::fundraising::database::slave {
	$mysql_role = "slave"
	include role::fundraising::database
	monitor_service {
		"mysql slave delay":
			description => "MySQL Slave Delay",
			check_command => "nrpe_check_mysql_slave_delay",
			critical => false
	}
}


class role::fundraising::database::dump_slave {
	system_role { "role::fundraising::database::dump": description => "Fundraising Database Dump/Backup" }
	include role::fundraising::database::slave,
		misc::fundraising::backup::offhost

	file {
		'/usr/local/bin/dump_fundraisingdb':
			mode => 0755,
			owner => root,
			group => root,
			source => "puppet:///files/misc/scripts/dump_fundraisingdb";
		'/root/.dump_fundraisingdb':
			mode => 0400,
			owner => root,
			group => root,
			source => "puppet:///private/misc/fundraising/dump_fundraisingdb-${hostname}";
	}

	cron {
		'dump_fundraising_database':
			user => root,
			minute => '35',
			hour => '1',
			command => '/usr/local/bin/dump_fundraisingdb',
			ensure => present;
		'offhost_backups':
			user => root,
			minute => '35',
			hour => '1',
			command => '/usr/local/bin/offhost_backups',
			ensure => present;
	}
}


























# this is from storage3 and will probably just be removed
# moved it here to get it out of site.pp in the meantime
#class role::fundraising::database {
#
#	$db_cluster = "fundraisingdb"
#
#	include role::db::core,
#		role::fundraising::database::slave,
#		role::fundraising::database::dump,
#		mysql::packages,
#		mysql::mysqluser,
#		mysql::datadirs,
#		mysql::conf,
#		svn::client,
#		groups::wikidev,
#		accounts::khorn,
#		accounts::pgehres,
#		accounts::zexley,
#		misc::fundraising::backup::offhost,
#		misc::fundraising::backup::archive
#
#	cron {
#		'offhost_backups':
#			user => root,
#			minute => '30',
#			hour => '23',
#			command => '/usr/local/bin/offhost_backups',
#			ensure => present,
#	}
#
#}
