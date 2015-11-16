# Class: mysql::params
#
#   The mysql configuration settings.
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class mysql::params {

    $bind_address        = '127.0.0.1'
    $port                = 3306
    $etc_root_password   = false
    $ssl                 = false
    $restart             = false

    $service_provider    = $::initsystem

    if os_version('ubuntu <= precise') {
        $ver = '5.1'
    } else {
        $ver = '5.5'
    }

    $client_package_name  = "mysql-client-${ver}"
    $server_package_name  = "mysql-server-${ver}"

    $socket               = "/run/mysqld/mysqld.sock"
    $pidfile              = "/run/mysqld/mysqld.pid"
    $datadir              = '/var/lib/mysql'
    $log_error            = '/var/log/mysql/mysql.err'

    $basedir              = '/usr'
    $service_name         = 'mysql'
    $config_file          = '/etc/mysql/my.cnf'
    $ruby_package_name    = 'libmysql-ruby'
    $python_package_name  = 'python-mysqldb'
    $php_package_name     = 'php5-mysql'
    $java_package_name    = 'libmysql-java'
    $root_group           = 'root'
    $ssl_ca               = '/etc/mysql/cacert.pem'
    $ssl_cert             = '/etc/mysql/server-cert.pem'
    $ssl_key              = '/etc/mysql/server-key.pem'
}
