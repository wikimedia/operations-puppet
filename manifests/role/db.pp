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
    mysql_multi_instance

   class { mysql :
    package_name => 'mariadb-client-5.5'
   }

  ## some per-node monitoring here

  ## for key in instances, make a mysql instance. need port, innodb_log_file_size, and amount of ram
  $instances_keys = keys($instances)
  mysql_multi_instance::instance { $instances_keys :
    port                 => $role::db::sanitarium::instances[$name]['port'],
    innodb_log_file_size => $role::db::sanitarium::instances[$name]['innodb_log_file_size'],
    ram                  => $role::db::sanitarium::instances[$name]['ram'],
  }

}

class role::db::labsdb( $instances = {} ) {
  $cluster = "mysql"

  system_role {"role::db::labsdb": description => "labsdb dbs for labs use" }

  include standard

  class { mysql :
    package_name => 'mariadb-client-5.5'
  }
}
