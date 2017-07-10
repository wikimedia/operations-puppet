# == Class: profile::piwik::backup
#
# Periodical backups of the Piwik database tables using Bacula.
#
class profile::piwik::backup (
    $backup_username    = hiera('profile::piwik::backup_username'),
    $backup_password    = hiera('profile::piwik::backup_password'),
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
        content => "[client]\nuser=${backup_username}\npassword=${backup_password}\n",
    }

    backup::mysqlset {'piwik':
        xtrabackup       => false,
        per_db           => true,
        innodb_only      => true,
        binlog           => false,
        slave            => false,
        local_dump_dir   => '/srv/backups',
        password_file    => '/etc/mysql/conf.d/dumps.cnf',
        method           => 'predump',
        mysql_binary     => '/usr/bin/mysql',
        mysqldump_binary => '/usr/bin/mysqldump',
        jobdefaults      => "Weekly-${profile::backup::host::day}-${profile::backup::host::pool}",
    }
}
