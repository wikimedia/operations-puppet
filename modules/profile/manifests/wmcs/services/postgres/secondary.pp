class profile::wmcs::services::postgres::secondary (
    $postgres_primary = hiera('profile::wmcs::services::postgres::primary', undef),
    $root_dir = hiera('profile::wmcs::services::postgres::root_dir', '/srv/postgres'),
){
    include profile::wmcs::services::postgres::common
    class {'::postgresql::postgis': }
    include ::passwords::postgres

    class {'postgresql::slave':
        master_server    => $postgres_primary,
        replication_pass => $passwords::postgres::replication_pass,
        includes         => 'tuning.conf',
        root_dir         => $root_dir,
    }
}
