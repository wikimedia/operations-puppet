class profile::wmcs::services::postgres::secondary (
    $postgres_primary = hiera('profile::wmcs::services::postgres::primary', undef),
    $replication_pass = hiera('profile::wmcs::services::postgres::replication_pass'),
    $root_dir = hiera('profile::wmcs::services::postgres::root_dir', '/srv/postgres'),
){
    include profile::wmcs::services::postgres::common
    class {'::postgresql::postgis': }

    class {'postgresql::slave':
        master_server    => $postgres_primary,
        replication_pass => $replication_pass,
        includes         => 'tuning.conf',
        root_dir         => $root_dir,
    }
}
