@monitor_group { "fundraising_eqiad": description => "fundraising eqiad" }
@monitor_group { "fundraising_pmtpa": description => "fundraising pmtpa" }


class role::fundraising::messaging {
	system_role { "fundraiser messaging": description => "fundraiser messaging" }
	$cluster = "fundraising"
	$nagios_group = "${cluster}_${::site}"
	include standard,
		groups::wikidev,
		accounts::khorn
}


class role::fundraising::logger {
	system_role { "fundraiser logging": description => "fundraiser logging" }
	$nagios_group = "${cluster}_${::site}"
	include standard,
		groups::wikidev,
		accounts::khorn,
		accounts::pgehres
}


class role::fundraising::civicrm {
	system_role { "fundraiser civicrm": description => "fundraiser civicrm" }

	# variables used in fundraising exim template
	# TODO: properly scope these
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


# this is from storage3 and will probably just be removed
# moved it here to get it out of site.pp in the meantime
class role::fundraising::database {

	system_role { "fundraiser database": description => "fundraiser database" }

	$db_cluster = "fundraisingdb"

	include role::db::core,
		role::db::fundraising::slave,
		role::db::fundraising::dump,
		mysql::packages,
		mysql::mysqluser,
		mysql::datadirs,
		mysql::conf,
		svn::client,
		groups::wikidev,
		accounts::khorn,
		accounts::pgehres,
		accounts::zexley,
		misc::fundraising::backup::offhost,
		misc::fundraising::backup::archive

	cron {
		'offhost_backups':
			user => root,
			minute => '30',
			hour => '23',
			command => '/usr/local/bin/offhost_backups',
			ensure => present,
	}

}
