# The WMF autoinstaller partman db.cfg mounts /a

class mariadb::datadir {

    file { '/a/sqldata':
        ensure  => directory,
        owner   => 'mysql',
        group   => 'mysql',
        mode    => '0755',
    }

    file { '/a/tmp':
        ensure  => directory,
        owner   => 'mysql',
        group   => 'mysql',
        mode    => '0755',
    }
}
