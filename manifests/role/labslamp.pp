# = class: role::simplelamp
#
# Sets up a simple LAMP server for use by arbitrary php applications
class role::simplelamp(
    $mysql_local = true,
) {
    include ::apache
    include ::apache::mod::php5
    include ::apache::mod::rewrite

    require_package('php5-mysql', 'php5-cli')

    $bind_address = $mysql_local ? {
        true   => '127.0.0.1',
        false  => '0.0.0.0',
    }

    # Simple mysql
    class { '::mysql::server':
        config_hash        => {
            'datadir'      => '/srv/mysql',
            'bind_address' => $bind_address,
        }
    }
}

# Deprecated older role that no longer works
class role::lamp::labs {

    include role::labs-mysql-server
    include ::apache
    include ::apache::mod::php5
    require_package('php5-mysql')
    require_package('php5-cli')

}
