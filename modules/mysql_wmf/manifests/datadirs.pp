class mysql_wmf::datadirs {
    file { '/a/sqldata':
        ensure  => directory,
        owner   => 'mysql',
        group   => 'mysql',
        mode    => '0755',
        require => User['mysql'],
    }
    file { '/a/tmp':
        ensure  => directory,
        owner   => 'mysql',
        group   => 'mysql',
        mode    => '0755',
        require => User['mysql'],
    }
}

