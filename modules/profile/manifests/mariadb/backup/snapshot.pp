# Postprocess xtrabackup/mariabackup snapshots so they
# are placed on the right place at the provisioning server
class profile::mariadb::backup::snapshot {
    require_package(
        'python3',  # also requires either mariabackup or wmf-mariadb*
        'python3-yaml',
        'python3-pymysql',
    )

    file { '/srv/backups/snapshots':
        ensure  => directory,
        owner   => 'dump',
        group   => 'dump',
        mode    => '0600', # implicitly 0700 for dirs
        require => File['/srv/backups'],
    }

    file { ['/srv/backups/snapshots/ongoing',
            '/srv/backups/snapshots/latest',
            '/srv/backups/snapshots/archive',
        ]:
        ensure  => directory,
        owner   => 'dump',
        mode    => '0600', # implicitly 0700 for dirs
        require => File['/srv/backups/snapshots'],
    }
}
