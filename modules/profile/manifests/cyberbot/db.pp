# sets up a dedicated DB server for cyberbot
class profile::cyberbot::db{

    file { '/srv/mysql':
        ensure => 'directory',
        owner  => 'mysql',
        group  => 'mysql',
    }

    file { '/srv/mysql/data':
        ensure  => 'directory',
        owner   => 'mysql',
        group   => 'mysql',
        require => File['/srv/mysql'],
    }

    require_package('mariadb-server')

    file { '/etc/mysql/my.cnf':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///modules/profile/cyberbot/my.cnf',
        require => Package['mariadb-server'];
    }

}
