# the contents of the next 2 classes should go over to
# db_maintenance module on puppet db-classes refactoring
class role::mariadb::maintenance {
    # TODO: check if both of these are still needed
    include mysql
    package { 'percona-toolkit':
        ensure => latest,
    }

    # place from which tendril-related cron jobs are run
    include passwords::tendril

    class { 'tendril::maintenance':
        tendril_host     => 'db1011.eqiad.wmnet',
        tendril_user     => 'watchdog',
        tendril_password => $passwords::tendril::db_pass,
    }
}

