# this is for checks from the percona-nagios-checks project
# http://percona-nagios-checks.googlecode.com
class mysql_wmf::monitor::percona::files {
    include passwords::nagios::mysql
    $mysql_check_pass = $passwords::nagios::mysql::mysql_check_pass

    file { "${icinga::config_vars::icinga_config_dir}/nrpe.d/nrpe_percona.cfg":
        owner   => 'root',
        group   => 'nagios',
        mode    => '0440',
        content => template('mysql_wmf/icinga/nrpe_percona.cfg.erb'),
        notify  => Service[nagios-nrpe-server],
    }
    file { '/usr/lib/nagios/plugins/percona':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/percona/check_lvs':
        source => 'puppet:///modules/mysql_wmf/icinga/percona/check_lvs',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
    file { '/usr/lib/nagios/plugins/percona/check_mysql_deadlocks':
        source => 'puppet:///modules/mysql_wmf/icinga/percona/check_mysql_deadlocks',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
    file { '/usr/lib/nagios/plugins/percona/check_mysql_idle_transactions':
        source => 'puppet:///modules/mysql_wmf/icinga/percona/check_mysql_idle_transactions',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
    file { '/usr/lib/nagios/plugins/percona/check_mysql_recent_restart':
        source => 'puppet:///modules/mysql_wmf/icinga/percona/check_mysql_recent_restart',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
    file { '/usr/lib/nagios/plugins/percona/check_mysql_slave_delay':
        source => 'puppet:///modules/mysql_wmf/icinga/percona/check_mysql_slave_delay',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
    file { '/usr/lib/nagios/plugins/percona/check_mysql_slave_running':
        source => 'puppet:///modules/mysql_wmf/icinga/percona/check_mysql_slave_running',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
    file { '/usr/lib/nagios/plugins/percona/check_mysql_unauthenticated_users':
        source => 'puppet:///modules/mysql_wmf/icinga/percona/check_mysql_unauthenticated_users',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
    file { '/usr/lib/nagios/plugins/percona/check_mysqld_deleted_files':
        source => 'puppet:///modules/mysql_wmf/icinga/percona/check_mysqld_deleted_files',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
    file { '/usr/lib/nagios/plugins/percona/check_mysqld_file_ownership':
        source => 'puppet:///modules/mysql_wmf/icinga/percona/check_mysqld_file_ownership',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
    file { '/usr/lib/nagios/plugins/percona/check_mysqld_frm_ibd':
        source => 'puppet:///modules/mysql_wmf/icinga/percona/check_mysqld_frm_ibd',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
    file { '/usr/lib/nagios/plugins/percona/check_mysqld_pid_file':
        source => 'puppet:///modules/mysql_wmf/icinga/percona/check_mysqld_pid_file',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
    file { '/usr/lib/nagios/plugins/percona/utils.sh':
        source => 'puppet:///modules/mysql_wmf/icinga/percona/utils.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
        # project has become "percona monitoring plugins". migrate starting now:
    file { '/usr/lib/nagios/plugins/percona/pmp-check-mysql-processlist':
        source => 'puppet:///modules/mysql_wmf/icinga/percona/pmp-check-mysql-processlist',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
    file { '/usr/lib/nagios/plugins/percona/pmp-check-mysql-innodb':
        source => 'puppet:///modules/mysql_wmf/icinga/percona/pmp-check-mysql-innodb',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
}
