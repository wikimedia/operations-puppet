define mysql_multi_instance::instance(
    $instances = {}
    ){
    $port                 = $instances[$name]['port']
    $innodb_log_file_size = $instances[$name]['innodb_log_file_size']
    $ram                  = $instances[$name]['ram']
    if has_key( $instances[$name], 'read_only') {
      $read_only = $instances[$name]['read_only']
    }else {
      $read_only = 1
    }
    if has_key( $instances[$name],  'repl_ignore_dbs') {
      $repl_ignore_dbs = $instances[$name]['repl_ignore_dbs']
    }else {
      $repl_ignore_dbs = false
    }
    if has_key( $instances[$name],  'repl_wild_ignore_tables') {
      $repl_wild_ignore_tables = prefix( $instances[$name]['repl_wild_ignore_tables'], '%.' )
    }else {
      $repl_wild_ignore_tables = false
    }
    if has_key( $instances[$name],  'binlog_format') {
      $binlog_format = $instances[$name]['binlog_format']
    }else {
      $binlog_format = "statement"
    }
    if has_key( $instances[$name],  'log_bin') {
      $log_bin = $instances[$name]['log_bin']
    }else {
      $log_bin = false
    }
    if has_key( $instances[$name],  'innodb_locks_unsafe_for_binlog') {
      $innodb_locks_unsafe_for_binlog = $instances[$name]['innodb_locks_unsafe_for_binlog']
    }else {
      $innodb_locks_unsafe_for_binlog = false
    }

    $serverid = inline_template("<%= ia = ipaddress.split('.'); server_id = ia[0] + ia[2] + ia[3] + String($port); server_id %>")
    include passwords::nagios::mysql
    $mysql_check_pass = $passwords::nagios::mysql::mysql_check_pass

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

    service {
      "mysql-${port}":
        enabled => true,
        require  => File["/etc/init.d/mysql-${port}"],
    }

    ## some per-instance monitoring here
    nrpe::monitor_service { "mysql_recent_restart_${port}":
      description => "MySQL Recent Restart Port ${port}",
      nrpe_command => "/usr/lib/nagios/plugins/percona/check_mysql_recent_restart -H localhost -S /tmp/mysql.${port}.sock -l nagios -p ${mysql_check_pass}"
    }
    nrpe::monitor_service { "mysql_idle_transaction_${port}":
      description => "MySQL Idle Transactions Port ${port}",
      nrpe_command => "/usr/lib/nagios/plugins/percona/check_mysql_idle_transactions -H localhost -S /tmp/mysql.${port}.sock -l nagios -p ${mysql_check_pass}"
    }
    nrpe::monitor_service { "mysql_slave_delay_${port}":
      description => "MySQL Slave Delay Port ${port}",
      nrpe_command => "/usr/lib/nagios/plugins/percona/check_mysql_slave_delay -H localhost -S /tmp/mysql.${port}.sock -l nagios -p ${mysql_check_pass} -w 30 -c 180"
    }
    nrpe::monitor_service { "mysql_slave_running_${port}":
      description => "MySQL Slave Running Port ${port}",
      nrpe_command => "/usr/lib/nagios/plugins/percona/check_mysql_slave_running -H localhost -S /tmp/mysql.${port}.sock -l nagios -p ${mysql_check_pass} "
    }

    mysql_multi_instance::config {"my.cnf.${port}" :
      settings => {
        'client' => {
          'port'   => $port,
          'socket' => "/tmp/mysql.${port}.sock",
        },
        # FIXME - make threads and io-capacity dynamic
        'mysqld' => {
          'server_id'                   => $serverid,
          'read_only'                   => $read_only,
          'user'                        => "mysql",
          'socket'                      => "/tmp/mysql.${port}.sock",
          'port'                        => $port,
          'datadir'                     => "/a/sqldata.${port}/",
          'tmpdir'                      => "/a/tmp.${port}/",
          'query_cache_type'            => 0,
          'log_slow_verbosity'          => 'Query_plan',
          'innodb-adaptive-flushing'    => 1,
          'innodb-buffer-pool-size'     => $ram,
          'innodb_use_native_aio'       => 0,
          'innodb-flush-method'         => "O_DIRECT",
          'innodb-io-capacity'          => 1000,
          'innodb-log-file-size'        => $innodb_log_file_size,
          'innodb-old-blocks-pct'       => 80,
          'innodb-old-blocks-time'      => 1000,
          'innodb-read-io-threads'      => 16,
          'innodb-thread-concurrency'   => 0,
          'innodb-use-sys-malloc'       => true,
          'innodb-write-io-threads'     => 8,
          'innodb-checksums'            =>1,
          'innodb_file_per_table'       => true,
          'innodb_locks_unsafe_for_binlog' => $innodb_locks_unsafe_for_binlog,
          'skip-external-locking'       => true,
          'skip-name-resolve'           => true,
          'key_buffer'                  => 1M,
          'max_allowed_packet'          => "16M",
          'thread_stack'                => "192K",
          'thread_cache_size'           => 300,
          'max_connections'             => 5000,
          'table_open_cache'            => 50000,
          'table_definition_cache'      => 40000,
          'query_cache_size'            => 0,
          'log_slow_queries'            => true,
          'long_query_time'             => 0.45,
          'log_bin'                     => $log_bin,
          'log_slave_updates'           => true,
          'sync_binlog'                 => 1,
          'binlog_cache_size'           => "1M",
          'max_binlog_size'             => "1000M",
          'binlog_format'               => $binlog_format,
          'expire_logs_days'            => 30,
          'connect_timeout'             => 3,
          'back_log'                    => 1000,
          'max_connect_errors'          => 1000000000,
          'temp-pool'                   => true,
          'query_cache_type'            => 0,
          'log_slow_verbosity'          => "Query_plan",
          'optimizer_switch'            => '\'mrr=on,mrr_cost_based=on,mrr_sort_keys=on,optimize_join_buffer_size=on,extended_keys=off\'',
          'replicate-ignore-db'         => $repl_ignore_dbs,
          'replicate-wild-ignore-table' => $repl_wild_ignore_tables,
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
