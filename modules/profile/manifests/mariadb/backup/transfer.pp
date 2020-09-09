# Create remote xtrabackup/mariabackup backups
# By using transfer.py
class profile::mariadb::backup::transfer {
    include ::passwords::mysql::dump

    require_package(
        'transferpy',
        'python3-yaml',
    )

    # we can override transferpy defaults if needed
    file { '/etc/transferpy/transferpy.conf':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/profile/mariadb/transferpy.conf',
    }

    # mysql dir must be handled by a separate profile, not done here
    # as it depends on the available owner (root, mysql, dump)
    # file { '/etc/mysql':
    # }

    $stats_user = $passwords::mysql::dump::stats_user
    $stats_password = $passwords::mysql::dump::stats_pass
    # Configuration file where the daily backup routine (source hosts,
    # destination, statistics db is configured
    # Can contain private data like db passwords
    file { '/etc/mysql/backups.cnf':
        ensure    => present,
        owner     => 'root',
        group     => 'root',
        mode      => '0400',
        show_diff => false,
        content   => template("profile/mariadb/backup_config/${::hostname}.cnf.erb"),
        require   => [File['/etc/mysql'],
        ],
    }

    # Small utility that reads the backup configuration and produces
    # snapshots of all configured hosts
    file { '/usr/local/bin/remote_backup_mariadb.py':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => 'puppet:///modules/profile/mariadb/remote_backup_mariadb.py',
        require => [Package['transferpy'],
                    Package['python3-yaml'],
                    File['/etc/mysql/backups.cnf'],
        ],
    }

    cron { 'regular_snapshot':
        minute  => 0,
        hour    => 19,
        weekday => [0, 2, 3, 5],
        user    => 'root',
        command => "/usr/bin/python3 \
/usr/local/bin/remote_backup_mariadb.py > /dev/null 2>&1",
        require => [File['/usr/local/bin/remote_backup_mariadb.py'],
        ],
    }
}
