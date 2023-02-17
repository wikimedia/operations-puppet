# SPDX-License-Identifier: Apache-2.0
class profile::openstack::base::galera::backup(
    String              $back_user             = lookup('profile::openstack::base::galera::backup_user'),
    String              $back_pass             = lookup('profile::openstack::base::galera::backup_password'),
    ) {

    include ::profile::backup::host

    file { '/srv/backups':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0600', # implicitly 0700 for dirs
    }

    file { '/etc/mysql/conf.d/dumps.cnf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => "[client]\nuser=${back_user}\npassword=\'${back_pass}\'\n",
        require => Class['galera'],
    }

    # Backups older than 15 days will be deleted by the predump script before
    # the mysqldump, so a cron is not needed.
    backup::mysqlset { "db_backups_${::hostname}":
        xtrabackup       => false, # only used for method => bpipe
        per_db           => true,
        innodb_only      => true,
        binlog           => false,
        slave            => false,
        local_dump_dir   => '/srv/backups',
        password_file    => '/etc/mysql/conf.d/dumps.cnf',
        method           => 'predump',
        mysql_binary     => '/usr/bin/mysql',
        mysqldump_binary => '/usr/bin/mysqldump',
    }
}
