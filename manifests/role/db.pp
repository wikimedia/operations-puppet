# role/db.pp
# db::core for a few remaining m1 boxes
# or db::sanitarium or db::labsdb for the labsdb project

class role::db::core {
	$cluster = "mysql"

	system_role { "db::core": description => "Core Database server" }

	include standard,
		mysql_wmf
}


class role::db::sanitarium( $instances = {} ) {
## $instances must be a 2-level hash of the form:
## 'shard9001' => { port => NUMBER, innodb_log_file_size => "CORRECT_M", ram => "HELLA_G" },
## 'shard9002' => { port => NUMBER+1, innodb_log_file_size => "CORRECT_M", ram => "HELLA_G" },
	$cluster = "mysql"

	system_role {"role::db::sanitarium": description => "pre-labsdb dbs for Data Sanitization" }

	include standard,
		cpufrequtils,
		mysql_multi_instance

	class { mysql :
		package_name => 'mariadb-client-5.5'
	}

	## for key in instances, make a mysql instance. need port, innodb_log_file_size, and amount of ram
	$instances_keys = keys($instances)
	mysql_multi_instance::instance { $instances_keys :
		instances => $instances
	}

	## some per-node monitoring here
	$instances_count = size($instances_keys)

	file { "/usr/lib/nagios/plugins/percona":
		ensure => directory,
		recurse => true,
		owner => root,
		group => root,
		mode => 0555,
		source => "puppet:///files/icinga/percona";
	}

	nrpe::monitor_service { "mysqld":
		description => "mysqld processes",
		nrpe_command => "/usr/lib/nagios/plugins/check_procs -c ${instances_count}:${instances_count} -C mysqld"
	}

}

class role::db::labsdb( $instances = {} ) {
## $instances must be a 2-level hash of the form:
## 'shard9001' => { port => NUMBER, innodb_log_file_size => "CORRECT_M", ram => "HELLA_G" },
## 'shard9002' => { port => NUMBER+1, innodb_log_file_size => "CORRECT_M", ram => "HELLA_G" },
	$cluster = "mysql"

	system_role {"role::db::labsdb": description => "labsdb dbs for labs use" }

	include standard,
		cpufrequtils,
		mysql_multi_instance

	class { mysql :
		package_name => 'mariadb-client-5.5'
	}

	## for key in instances, make a mysql instance. need port, innodb_log_file_size, and amount of ram
	$instances_keys = keys($instances)
	mysql_multi_instance::instance { $instances_keys :
		instances => $instances
	}

	## some per-node monitoring here
	$instances_count = size($instances_keys)

	file { "/usr/lib/nagios/plugins/percona":
		ensure => directory,
		recurse => true,
		owner => root,
		group => root,
		mode => 0555,
		source => "puppet:///files/icinga/percona";
	}

	nrpe::monitor_service { "mysqld":
		description => "mysqld processes",
		nrpe_command => "/usr/lib/nagios/plugins/check_procs -c ${instances_count}:${instances_count} -C mysqld"
	}
}
