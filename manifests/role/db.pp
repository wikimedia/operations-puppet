# role/db.pp
# db::core and db::es

class role::db::core {
	$cluster = "mysql"

	system_role { "db::core": description => "Core Database server" }

	include standard,
		mysql
}

class role::db::es($mysql_role = "slave") {
	$cluster = "mysql"

	$nagios_group = "es_${::site}"

	system_role { "db::es": description => "External Storage server (${mysql_role})" }

	include	standard,
		mysql,
		mysql::mysqluser,
		mysql::datadirs,
		mysql::conf,
		mysql::mysqlpath,
		mysql::monitor::percona::es,
		mysql::packages,
		nrpe

}
