class mysql_wmf::monitor::percona inherits mysql_wmf {
    $crit = $::master
    require 'mysql_wmf::monitor::percona::files'

    nrpe::monitor_service { 'mysqld':
        description   => 'mysqld processes',
        nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C mysqld',
        critical      => $crit,
    }
    monitor_service { 'mysql recent restart':
        description   => 'MySQL Recent Restart',
        check_command => 'nrpe_check_mysql_recent_restart',
        critical      => $crit,
    }
    monitor_service { 'full lvs snapshot':
        description   => 'Full LVS Snapshot',
        check_command => 'nrpe_check_lvs',
        critical      => false,
    }
    monitor_service { 'mysql idle transaction':
        description   => 'MySQL Idle Transactions',
        check_command => 'nrpe_check_mysql_idle_transactions',
        critical      => false,
    }
    monitor_service { 'mysql slave running':
        description   => 'MySQL Slave Running',
        check_command => 'nrpe_check_mysql_slave_running',
        critical      => false,
    }
    monitor_service { 'mysql replication heartbeat':
        description   => 'MySQL Replication Heartbeat',
        check_command => 'nrpe_check_mysql_slave_heartbeat',
        critical      => false,
    }
    monitor_service { 'mysql slave delay':
        description   => 'MySQL Slave Delay',
        check_command => 'nrpe_check_mysql_slave_delay',
        critical      => false,
    }
    monitor_service { 'mysql processlist':
        description   => 'MySQL Processlist',
        check_command => 'nrpe_pmp_check_mysql_processlist',
        critical      => false,
    }
    monitor_service { 'mysql innodb':
        description   => 'MySQL InnoDB',
        check_command => 'nrpe_pmp_check_mysql_innodb',
        critical      => false,
    }
}
