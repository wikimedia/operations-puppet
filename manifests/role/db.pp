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
    $port
    ){

    $serverid = inline_template("<%= ia = ipaddress.split('.'); server_id = ia[0] + ia[2] + ia[3] + String($port); server_id %>")
    $ram      = inline_template("<%= ram = memorysize.split[0]; ram = Float(ram) * 0.75; ram = ram.round; ram = String(ram); ram %>G")

    include role::db::sanitarium::base

    class { mysql::server :
      package_name     => 'mariadb-server-5.5',
      config_hash      => {
        port              => $port,
        config_file       => "/etc/my.cnf.$port",
        socket            => "/tmp/mysql.$port.sock",
        pidfile           => "/a/sqldata.$port/mysql.pid",
        datadir           => "/a/sqldata.$port/",
        multi_instance    => true,
      }
    }

    file { "/etc/init.d/mysql-${port}":
      owner => root,
      group => root,
      mode => 0555,
      source => "puppet:///modules/mysql/mysql.init.erb"
    }

    mysql::server::config {"my.cnf.${port}" :
      settings => {
        'mysqld' => {
          'server_id' => $serverid,
          'read_only' => 1,
          'innodb_file_per_table' => true,
          'query_cache_type' => 0,
          'log_slow_verbosity' => 'Query_plan',
          'optimizer_switch' => 'extended_keys=on',
          'innodb-adaptive-flushing' => 1,
          'innodb-buffer-pool-size' => $ram,
          'innodb-flush-method' => 'O_DIRECT',
          'innodb-io-capacity' => 1000,
          'innodb-log-file-size' => "500M",
          'innodb-old-blocks-pct' => 80,
          'innodb-old-blocks-time' => 1000,
          'innodb-read-io-threads' => 16,
          'innodb-thread-concurrency' => 0,
          'innodb-use-sys-malloc' => true,
          'innodb-write-io-threads' => 8,
          'innodb-checksums' =>1,
          'max_connections' => 5000,
          'table_open_cache'       => 50000,
          'table_definition_cache' => 40000,
          'query_cache_size'        => 0,
          'log_slow_queries' => true,
          'long_query_time' => 0.45,
          'log_bin' => true,
          'log_slave_updates' => true,
          'sync_binlog' => 1,
          'binlog_cache_size' => "1M",
          'max_binlog_size'         => "1000M",
          'binlog_format'=> "statement",
          'expire_logs_days' => 30,
          'connect_timeout'=>3,
          'back_log'=>1000,
          'max_connect_errors'=>1000000000,
          'temp-pool' => true,
        }
      }
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
