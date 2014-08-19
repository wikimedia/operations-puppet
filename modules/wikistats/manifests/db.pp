# the database server setup for the wikistats site
class wikistats::db {

    package { 'mariadb-server':
        ensure => present,
    }

}
