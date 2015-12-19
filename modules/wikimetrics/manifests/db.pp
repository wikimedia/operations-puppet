# == Class: wikimetrics::db
# Sets up mysql server for Wikimetrics
class wikimetrics::web {

    class { '::mysql::server':
        config_hash        => {
            'datadir'      => '/srv/mysql',
            'bind_address' => '127.0.0.1',
        },
        require => Package['mysql-server'],
    }
}
