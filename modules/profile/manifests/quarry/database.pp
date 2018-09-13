# = Class: profile::quarry::database
#
# Sets up a mysql database for use by Quarry web frontends
# and Quarry query runners
class profile::quarry::database {
    class { '::mariadb::packages': }

    class { '::mariadb::config':
        basedir => '/usr',
        datadir => '/srv/sqldata',
    }
}
