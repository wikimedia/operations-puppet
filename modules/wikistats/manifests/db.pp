# the database server setup for the wikistats site
class wikistats::db {

    package { 'mariadb-server':
        ensure => present,
    }

    package { 'php5-mysql':
        ensure => present,
    }
}
