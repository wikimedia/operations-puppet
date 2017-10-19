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

    class { '::mysql::server':
        package_name => 'mariadb-server',
        config_hash  => {
            'datadir'      => '/srv/mysql/data',
            'bind_address' => '0.0.0.0',
        },
    }
}
