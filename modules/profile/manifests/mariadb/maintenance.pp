# maintenance needed on maintenance hosts for tendril
class profile::mariadb::maintenance(
    $ensure = hiera('profile::mariadb::maintenance::ensure'),
    ) {
    # The role should install profile::mariadb::client

    # place from which tendril-related cron jobs are run
    include passwords::tendril

    class { 'tendril::maintenance':
        ensure           => $ensure,
        tendril_host     => 'db1011.eqiad.wmnet',
        tendril_user     => 'watchdog',
        tendril_password => $passwords::tendril::db_pass,
    }
}
