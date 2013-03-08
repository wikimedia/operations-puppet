@monitor_group { "fundraising_eqiad": description => "fundraising eqiad" }
@monitor_group { "fundraising_pmtpa": description => "fundraising pmtpa" }

class role::fundraising::messaging {
	$cluster = "fundraising"
	$nagios_group = "${cluster}_${::site}"
	include standard,
		groups::wikidev,
		admins::fr-tech

	monitor_service { "check_cclimbo":
		description => "check_cclimbo",
		check_command => "nsca-fail!1!'passive check_cclimbo is awol'",
		passive => "true",
		freshness => 300,
		retries => 2,
		contact_group => 'fundraising'
	}
	monitor_service { "check_donations":
		description => "check_donations",
		check_command => "nsca-fail!1!'passive check_donations is awol'",
		passive => "true",
		freshness => 300,
		retries => 2,
		contact_group => 'fundraising'
	}
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
		#accounts::pcoombe, # no longer involved with fundraising
		#accounts::rfaulk, # no longer involved with fundraising
		accounts::zexley,
		accounts::sahar,
		admins::fr-tech,
		admins::roots,
		apt,
		backup::client,
		ganglia,
		misc::fundraising,
		misc::fundraising::backup::backupmover_user,
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

	monitor_service { "smtp": description => "Exim SMTP", check_command => "check_smtp" }
	monitor_service { "http": description => "HTTP", check_command => "check_http" }
}


class role::fundraising::database {
	$cluster = "fundraising"
	$nagios_group = "${cluster}_${::site}"

	system_role { "role::fundraising::database": description => "Fundraising Database (${mysql_role})" }

	include standard,
		mysql_wmf,
		mysql_wmf::conf,
		mysql_wmf::datadirs,
		mysql_wmf::mysqluser,
		mysql_wmf::packages

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
	monitor_service { "mysql slave delay": description => "MySQL Slave Delay", check_command => "nrpe_check_mysql_slave_delay", critical => true }
	monitor_service { "mysql slave running": description => "MySQL Slave Running", check_command => "nrpe_check_mysql_slave_running", critical => true }
	monitor_service { "mysqld": description => "mysqld processes", check_command => "nrpe_check_mysqld", critical => true }
}


class role::fundraising::database::dump_slave {
	system_role { "role::fundraising::database::dump": description => "Fundraising Database Dump/Backup" }
	include role::fundraising::database::slave,
		misc::fundraising::backup::backupmover_user

	class { 'misc::fundraising::backup::dump_fundraising_database': hour => 9, minute => 0 }
}
