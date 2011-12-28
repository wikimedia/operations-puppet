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

#class role::role::db::fundraising::dump {
#
#}
