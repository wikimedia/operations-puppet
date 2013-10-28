# coredb_mysql required directories
class coredb_mysql::base {
    require coredb_mysql::packages

    generic::systemuser { 'mysql':
        name  => 'mysql',
        shell => '/bin/sh',
        home  => '/home/mysql',
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
