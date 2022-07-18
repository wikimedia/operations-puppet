# SPDX-License-Identifier: Apache-2.0
# Postprocess xtrabackup/mariabackup snapshots so they
# are placed on the right place at the provisioning server
class profile::dbbackups::snapshot {
    ensure_packages([
        'wmfbackups',  # recommends either mariabackup or wmf-mariadb*
    ])
    require profile::mariadb::packages_wmf  # needed for xbstream and --prepare

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
        group   => 'dump',
        mode    => '0600', # implicitly 0700 for dirs
        require => File['/srv/backups/snapshots'],
    }
}
