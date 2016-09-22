# TODO do we want to have a class for PHP clients (php5-mysql) as well
# and rename this to mysql::client-cli?
class mysql_wmf::client {
    if versioncmp($::lsbdistrelease, '12.04') >= 0 {
        package { 'mysql-client-5.5':
            ensure => latest,
        }
    } else {
        package { 'mysql-client-5.1':
            ensure => latest,
        }
    }
}

