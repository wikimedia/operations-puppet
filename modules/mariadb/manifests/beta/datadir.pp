class mariadb::beta::datadir {

    file { '/mnt/sqldata':
        ensure  => directory,
        owner   => 'mysql',
        group   => 'mysql',
        mode    => '0755',
        require => User['mysql'],
    }

    file { '/mnt/tmp':
        ensure  => directory,
        owner   => 'mysql',
        group   => 'mysql',
        mode    => '0755',
        require => User['mysql'],
    }
}