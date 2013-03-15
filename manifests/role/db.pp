# role/db.pp
# db::core for a few remaining m1 boxes
# or db::sanitarium or db::labsdb for the labsdb project

class role::db::core {
	$cluster = "mysql"

	system_role { "db::core": description => "Core Database server" }

	include standard,
		mysql_wmf
}


class role::db::sanitarium {
  class base {
   $cluster = "mysql"

   system_role {"role::db::sanitarium": description => "pre-labsdb dbs for Data Sanitization" }

   include standard,
    mysql::params

   class { mysql :
    package_name => 'mariadb-client-5.5'
   }
  }

  define instance(
    $settings,
    $port
    ){

    include role::db::sanitarium::base

    class { mysql::config :
      port              => $port,
      service_name      => $mysql::params::service_name,
      config_file       => "/etc/mysql/my.cnf.$port",
      socket            => "/tmp/mysql.$port.sock",
      pidfile           => "/a/sqldata.$port/mysql.pid",
      datadir           => "/a/sqldata.$port/",
    }

    class { mysql::server :
      package_name     => 'mariadb-server-5.5',
      config_hash      => {
        'client' => {

        }
      }
    }

    mysql::server::config {"my.cnf.$port" :
      settings => $settings
    }
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
