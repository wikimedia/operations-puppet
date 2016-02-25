# == Class mysql_wmf::backupex
# Installs a wrapper script around innobackupex that automatically
# finds previous backup directories after the initial run and does
# incremental backups.
#
# Use mysql_wmf::backupex::job to install a cron job that regularly
# runs the mysql-backupex script.
#
class mysql_wmf::backupex {
    require_package('percona-xtrabackup')

    # Install backupex script for easy regular and incremental backups.
    file { '/usr/local/bin/mysql-backupex':
        source => 'puppet:///modules/mariadb/mysql-backupex',
        mode   => '0755',
    }

    file { '/var/log/mysql-backupex':
        ensure => 'directory'
    }

    logrotate::conf { 'mysql-backupex':
        source  => 'puppet:///modules/mysql_wmf/backupex/mysql-backupex.logrotate',
        require => [
            File['/usr/local/bin/mysql-backupex'],
            File['/var/log/mysql-backupex'],
        ],
    }
}
