# role/db.pp
# db::core and db::es

# Virtual resource for the monitoring server
@monitor_group { "es_pmtpa": description => "pmtpa External Storage" }
@monitor_group { "es_eqiad": description => "eqiad External Storage" }
@monitor_group { "mysql_pmtpa": description => "pmtpa mysql core" }
@monitor_group { "mysql_eqiad": description => "eqiad mysql core" }


class role::db::core {
	$cluster = "mysql"

	system_role { "db::core": description => "Core Database server" }

	include standard,
		mysql
}

