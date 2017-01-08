# = class: role::simplelamp
#
# Sets up a simple LAMP server for use by arbitrary php applications
#
# filtertags: labs-common
class role::simplelamp(
    $mysql_local = true,
    $mysql_datadir = '/srv/mysql',
) {
    include ::apache
    include ::apache::mod::php5
    include ::apache::mod::rewrite
    include ::memcached

    require_package('php5-mysql', 'php5-cli')

    $bind_address = $mysql_local ? {
        true   => '127.0.0.1',
        false  => '0.0.0.0',
    }

    # Simple mysql
    class { '::mysql::server':
        config_hash => {
            'datadir'      => $mysql_datadir,
            'bind_address' => $bind_address,
        },
    }
}
