# maintenance needed on terbium (or similar) for tendril
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
