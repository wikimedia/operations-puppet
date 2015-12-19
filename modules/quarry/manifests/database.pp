# = Class: quarry::database
#
# Sets up a mysql database for use by Quarry web frontends
# and Quarry query runners
class quarry::database {
    $data_path = '/srv/mysql/data'

    class { 'mysql::server':
        package_name => 'mariadb-server',
        config_hash  => {
            'datadir'      => $data_path,
            'bind_address' => '0.0.0.0',
        }
    }
}

