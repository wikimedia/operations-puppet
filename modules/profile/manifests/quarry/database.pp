# = Class: profile::quarry::database
#
# Sets up a mysql database for use by Quarry web frontends
# and Quarry query runners
class profile::quarry::database {

    package { [
        'libmariadbclient18',
        'mariadb-client',
        'mariadb-server',
        'percona-toolkit',
    ]:
        ensure => present,
    }

    class { '::mariadb::config':
        basedir => '/usr',
        datadir => '/srv/sqldata',
    }
}
