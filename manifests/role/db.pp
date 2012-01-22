class role::db::fundraising {

	$cluster = "mysql"

	system_role { "role::db::fundraising": description => "Fundraising Database (${mysql_role})" }

	monitor_service {
		"mysql status":
			description => "MySQL ${mysql_role} status",
			check_command => "check_mysqlstatus!--${mysql_role}";
		"mysql replication":
			description => "MySQL replication status",
			check_command => "check_db_lag",
			ensure => $mysql_role ? {
				"master" => absent,
				"slave" => present
			};
	}

}

class role::db::fundraising::master {
	$mysql_role = "master"
	include role::db::fundraising
}

class role::db::fundraising::slave {
	$mysql_role = "slave"
	include role::db::fundraising
}

class role::db::fundraising::dump {

	system_role { "role::db::fundraising::dump": description => "Fundraising Database Dump/Backup" }

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
			source => "puppet:///private/misc/fundraising/dump_fundraisingdb.conf";
	}

	cron { 'dump_fundraising_database':
		user => root,
		minute => '35',
		hour => '1',
		command => '/usr/local/bin/dump_fundraisingdb',
		ensure => present,
	}

}
