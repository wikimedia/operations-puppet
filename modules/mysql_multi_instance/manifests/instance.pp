define mysql_multi_instance::instance(
    $instances = {}
    ){
    $port                 = $instances[$name]['port']
    $innodb_log_file_size = $instances[$name]['innodb_log_file_size']
    $ram                  = $instances[$name]['ram']

    $serverid = inline_template("<%= ia = ipaddress.split('.'); server_id = ia[0] + ia[2] + ia[3] + String($port); server_id %>")
    #$ram      = inline_template("<%= ram = memorysize.split[0]; ram = Float(ram) * 0.75; ram = ram.round; ram = String(ram); ram %>G")

    include mysql_multi_instance

    file {
      "/a/sqldata.${port}/":
        owner => mysql,
        group => mysql,
        mode => 0755,
        ensure => directory,
        require => User["mysql"];
      "/etc/init.d/mysql-${port}":
        owner => root,
        group => root,
        mode => 0555,
        content => template('mysql_multi_instance/mysql.init.erb');
    }

    ## some per-instance monitoring here

    mysql_multi_instance::config {"my.cnf.${port}" :
      settings => {
        'client' => {
          'port'   => $port,
          'socket' => "/tmp/mysql.sock",
        },
        'mysqld' => {
          'server_id'                 => $serverid,
          'read_only'                 => 1,
          'user'                      => "mysql",
          'socket'                    => "/tmp/mysql.${port}.sock",
          'port'                      => $port,
          'datadir'                   => "/a/sqldata.${port}/",
          'tmpdir'                    => "/a/tmp/",
          'query_cache_type'          => 0,
          'log_slow_verbosity'        => 'Query_plan',
          'innodb-adaptive-flushing'  => 1,
          'innodb-buffer-pool-size'   => $ram,
          'innodb-flush-method'       => "O_DIRECT",
          'innodb-io-capacity'        => 1000,
          'innodb-log-file-size'      => $innodb_log_file_size,
          'innodb-old-blocks-pct'     => 80,
          'innodb-old-blocks-time'    => 1000,
          'innodb-read-io-threads'    => 16,
          'innodb-thread-concurrency' => 0,
          'innodb-use-sys-malloc'     => true,
          'innodb-write-io-threads'   => 8,
          'innodb-checksums'          =>1,
          'innodb_file_per_table'     => true,
          'skip-external-locking'     => true,
          'skip-name-resolve'         => true,
          'key_buffer'                => 1M,
          'max_allowed_packet'        => "16M",
          'thread_stack'              => "192K",
          'thread_cache_size'         => 300,
          'max_connections'           => 5000,
          'table_open_cache'          => 50000,
          'table_definition_cache'    => 40000,
          'query_cache_size'          => 0,
          'log_slow_queries'          => true,
          'long_query_time'           => 0.45,
          'log_bin'                   => true,
          'log_slave_updates'         => true,
          'sync_binlog'               => 1,
          'binlog_cache_size'         => "1M",
          'max_binlog_size'           => "1000M",
          'binlog_format'             => "statement",
          'expire_logs_days'          => 30,
          'connect_timeout'           => 3,
          'back_log'                  => 1000,
          'max_connect_errors'        => 1000000000,
          'temp-pool'                 => true,
          'query_cache_type'          => 0,
          'log_slow_verbosity'        => "Query_plan",
          'optimizer_switch'          => '\'mrr=on,mrr_cost_based=on,mrr_sort_keys=on,optimize_join_buffer_size=on,extended_keys=off\'',
        },
        'mysqldump' => {
          'quick'              => true,
          'quote-names'        => true,
          'max_allowed_packet' => "16M",
        },
        'mysql' => {},
        'isamchk' => {
          'key_buffer' => "16M",
        }
      }
    }
}
