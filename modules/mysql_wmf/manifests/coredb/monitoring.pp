class mysql_wmf::coredb::monitoring(
  $crit          = false,
  $no_slave      = false,
  # Override contact_group if you want different
  # Icinga contact_groups notified for mysql errors
  # on this coredb instance.
  $contact_group = 'admins',
)
{

    include passwords::nagios::mysql
    $mysql_check_pass = $passwords::nagios::mysql::mysql_check_pass

    # this is for checks from the percona-nagios-checks project
    # http://percona-nagios-checks.googlecode.com
    file { '/etc/nagios/nrpe.d/nrpe_percona.cfg':
        owner   => 'root',
        group   => 'nagios',
        mode    => '0440',
        content => template('mysql_wmf/icinga/nrpe_coredb_percona.cfg.erb'),
        notify  => Service[nagios-nrpe-server],
    }
    file { '/usr/lib/nagios/plugins/percona':
        ensure  => directory,
        recurse => true,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/mysql_wmf/icinga/percona',
    }

    nrpe::monitor_service { 'mysql_disk_space':
        description   => 'MySQL disk space',
        nrpe_command  => '/usr/lib/nagios/plugins/check_disk -w 6% -c 3% -l -e',
        critical      => true,
        contact_group => $contact_group,
    }
    nrpe::monitor_service { 'mysqld':
        description   => 'mysqld processes',
        nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C mysqld',
        critical      => $crit,
        contact_group => $contact_group,
    }
    monitor_service { 'mysql recent restart':
        description   => 'MySQL Recent Restart',
        check_command => 'nrpe_check_mysql_recent_restart',
        critical      => $crit,
        contact_group => $contact_group,
    }
    monitor_service { 'mysql processlist':
        description   => 'MySQL Processlist',
        check_command => 'nrpe_pmp_check_mysql_processlist',
        critical      => false,
        contact_group => $contact_group,
    }
    monitor_service { 'mysql innodb':
        description   => 'MySQL InnoDB',
        check_command => 'nrpe_pmp_check_mysql_innodb',
        critical      => false,
        contact_group => $contact_group
    }

    if $no_slave == false {
        monitor_service { 'full lvs snapshot':
            description   => 'Full LVS Snapshot',
            check_command => 'nrpe_check_lvs',
            critical      => false,
            contact_group => $contact_group,
        }
        monitor_service { 'mysql idle transaction':
            description   => 'MySQL Idle Transactions',
            check_command => 'nrpe_check_mysql_idle_transactions',
            critical      => false,
            contact_group => $contact_group,
        }
        monitor_service { 'mysql replication heartbeat':
            description   => 'MySQL Replication Heartbeat',
            check_command => 'nrpe_check_mysql_slave_heartbeat',
            critical      => false,
            contact_group => $contact_group,
        }
        monitor_service { 'mysql slave delay':
            description   => 'MySQL Slave Delay',
            check_command => 'nrpe_check_mysql_slave_delay',
            critical      => false,
            contact_group => 'admins,analytics',
        }
        monitor_service { 'mysql slave running':
            description   => 'MySQL Slave Running',
            check_command => 'nrpe_check_mysql_slave_running',
            critical      => false,
            contact_group => $contact_group,
        }
    }
}
