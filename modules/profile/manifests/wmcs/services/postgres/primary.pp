class profile::wmcs::services::postgres::primary (
    $postgres_secondary = hiera('profile::wmcs::services::postgres::secondary', undef),
    $replication_pass = hiera('profile::wmcs::services::postgres::replication_pass', undef),
    $root_dir = hiera('profile::wmcs::services::postgres::root_dir', '/srv/postgres'),
){
    include profile::wmcs::services::postgres::common
    class {'::postgresql::postgis': }
    include ::profile::prometheus::postgres_exporter

    class { 'postgresql::master':
        includes => 'tuning.conf',
        root_dir => $root_dir,
    }

    if $postgres_secondary {
        $postgres_secondary_v4 = ipresolve($postgres_secondary, 4)
        if $postgres_secondary_v4 {
            postgresql::user { "replication@${postgres_secondary}-v4":
                ensure   => 'present',
                user     => 'replication',
                password => $replication_pass,
                cidr     => "${postgres_secondary_v4}/32",
                type     => 'host',
                method   => 'md5',
                attrs    => 'REPLICATION',
                database => 'all',
            }
        }
    }
}
