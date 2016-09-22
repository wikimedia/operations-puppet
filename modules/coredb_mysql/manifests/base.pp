# coredb_mysql required directories
class coredb_mysql::base {
    require coredb_mysql::packages

    group { 'mysql':
        ensure => present,
        name   => 'mysql',
        system => true,
    }

    user { 'mysql':
        shell      => '/bin/sh',
        home       => '/home/mysql',
        managehome => true,
        system     => true,
    }

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
