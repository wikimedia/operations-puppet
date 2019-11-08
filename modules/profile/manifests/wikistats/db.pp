# sets up a database for wikistats
class profile::wikistats::db {

    class { '::mariadb::packages': }

    class { '::mariadb::config':
        basedir => '/usr',
        datadir => '/var/lib/mysql',
    }
}
