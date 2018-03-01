# = class: role::simplelamp
#
# Sets up a simple LAMP server for use by arbitrary php applications
#
# filtertags: labs-common
class role::simplelamp(
    $mysql_local = true,
    $mysql_datadir = '/srv/mysql',
) {

    include ::memcached

    if os_version('debian >= stretch') {
        $php_module = "php7.0"
        require_package('php-mysql', 'php-cli')
    } else {
        $php_module = "php5"
        require_package('php5-mysql', 'php5-cli')
    }

    class { '::httpd':
        modules => ['rewrite', $php_module],
    }

    $bind_address = $mysql_local ? {
        true   => '127.0.0.1',
        false  => '0.0.0.0',
    }

    # Simple mysql
    class { '::mysql::server':
        config_hash => {
            'datadir'      => $mysql_datadir,
            'bind_address' => $bind_address,
        }
    }
}
