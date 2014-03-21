# The WMF autoinstaller partman db.cfg mounts /a.
# Check that /srv is suitable for each new role!

class mariadb::datadir {

    file { '/srv/sqldata':
        ensure  => directory,
        owner   => 'mysql',
        group   => 'mysql',
        mode    => '0755',
    }

    file { '/srv/tmp':
        ensure  => directory,
        owner   => 'mysql',
        group   => 'mysql',
        mode    => '0755',
    }
}
