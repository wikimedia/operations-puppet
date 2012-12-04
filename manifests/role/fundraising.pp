@monitor_group { "fundraising_eqiad": description => "fundraising eqiad" }
@monitor_group { "fundraising_pmtpa": description => "fundraising pmtpa" }

class role::fundraising::messaging {
	$cluster = "fundraising"
	$nagios_group = "${cluster}_${::site}"
	include standard,
		groups::wikidev,
		admins::fr-tech
}


class role::fundraising::logger {
	$cluster = "fundraising"
	$nagios_group = "${cluster}_${::site}"
	include standard,
		groups::wikidev,
		admins::fr-tech
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
	include
		accounts::mhernandez,
		accounts::pcoombe,
		accounts::rfaulk,
		accounts::zexley,
		admins::fr-tech,
		admins::roots,
		apt,
		backup::client,
		ganglia,
		misc::fundraising,
		misc::fundraising::backup::archive,
		misc::fundraising::backup::offhost,
		misc::fundraising::mail,
		nrpe,
		ntp::client,
        apt::update,
        base::access::dc-techs,
        base::decommissioned,
        base::environment,
        base::grub,
        base::monitoring::host,
        base::motd,
        base::platform,
        base::puppet,
        base::resolving,
        base::standard-packages,
        base::sysctl,
        base::tcptweaks,
        base::vimconfig,
        passwords::root,
        ssh

	if $hostname == "aluminium" {
		include misc::fundraising::jenkins,
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
	$cluster = "fundraising"
	$nagios_group = "${cluster}_${::site}"

	system_role { "role::fundraising::database": description => "Fundraising Database (${mysql_role})" }

	include standard,
		mysql,
		mysql::conf,
		mysql::datadirs,
		mysql::mysqluser,
		mysql::packages

}


class role::fundraising::database::master {
	$mysql_role = "master"
	$writable = true
	include role::fundraising::database
	monitor_service { "mysqld": description => "mysqld processes", check_command => "nrpe_check_mysqld", critical => true }
}


class role::fundraising::database::slave {
	$mysql_role = "slave"
	include role::fundraising::database
	monitor_service { "mysql slave delay": description => "MySQL Slave Delay", check_command => "nrpe_check_mysql_slave_delay", critical => false }
	monitor_service { "mysqld": description => "mysqld processes", check_command => "nrpe_check_mysqld", critical => false }
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
	}

	cron {
		'dump_fundraising_database':
			user => root,
			minute => '0',
			hour => '8',
			command => '/usr/local/bin/dump_fundraisingdb',
			ensure => present;
		'offhost_backups':
			user => root,
			minute => '0',
			hour => '11',
			command => '/usr/local/bin/offhost_backups',
			ensure => present;
	}
}
