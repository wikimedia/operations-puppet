# role/db.pp
# db::core for a few remaining m1 boxes
# or db::sanitarium or db::labsdb for the labsdb project

class role::db::core {
	$cluster = "mysql"

	system_role { "db::core": description => "Core Database server" }

	include standard,
		mysql_wmf
}


class role::db::sanitarium( $port ) {
  $cluster = "mysql"

  system_role {"role::db::sanitarium": description => "pre-labsdb dbs for Data Sanitization" }

  include standard

  include mysql::params
  class { mysql::config : }

  class { mysql::server :
    package_name     => 'mariadb-server-5.5',
    package_ensure   => 'present',
    port             => $port,
    config_hash      => {},
    enabled          => true,
    manage_service   => false
  }

  class { mysql :
    package_name => 'mariadb-client-5.5'
  }
}

class role::db::labsdb {
  $cluster = "mysql"

  system_role {"role::db::labsdb": description => "labsdb dbs for labs use" }

  include standard

  include mysql::params
  class { mysql::config : }

  class { mysql::server : }

  class { mysql :
    package_name => 'mariadb-client-5.5'
  }
}
