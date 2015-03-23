# the database server setup for the wikistats site
class wikistats::db {

    package { [ 'mariadb-server', 'php5-mysql']:
        ensure => present,
    }
}
