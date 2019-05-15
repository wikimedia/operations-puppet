# Create remote xtrabackup/mariabackup backups
# By using transfer.py
class profile::mariadb::backup::transfer {
    include ::passwords::mysql::dump

    require_package(
        'python3',
        'python3-yaml',
        'python3-pymysql',
        'cumin',
    )

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
        content   => template("profile/mariadb/backups-${::hostname}.cnf.erb"),
        require   => [File['/etc/mysql'],
        ],
    }

    # transfer.py: Base utility that allows remote file transfer between hosts,
    # as well as generating backups from mysql hosts
    file { '/usr/local/bin/transfer.py':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => 'puppet:///modules/profile/mariadb/transfer.py',
        require => [Package['python3'],
                    Package['cumin'],
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
        require => [File['/usr/local/bin/transfer.py'],
                    File['/etc/mysql/backups.cnf'],
                    Package['python3'],
                    Package['python3-yaml'],
                    Package['cumin'],
        ],
    }

    cron { 'regular_snapshot':
        minute  => 0,
        hour    => 19,
        weekday => [0,2,4],
        user    => 'root',
        command => "/usr/bin/systemd-cat -t mariadb-snapshots /usr/bin/python3 \
/usr/local/bin/remote_backup_mariadb.py 2>&1",
        require => [File['/usr/local/bin/remote_backup_mariadb.py'],
        ],
    }
}
