# TODO do we want to have a class for PHP clients (php5-mysql) as well
# and rename this to mysql::client-cli?
class mysql_wmf::client {
    if versioncmp($::lsbdistrelease, '12.04') >= 0 {
        require_package('mysql-client-5.5')
    } else {
        require_package('mysql-client-5.1')
    }
}

