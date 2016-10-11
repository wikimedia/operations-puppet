# Create users for PostgreSQL Replication / Monitoring
# This inner define should probably be replaced by iterator once we activate future parser
define role::maps::postgresql_slave_users(
    $ip_address,
    $replication_pass,
    $monitoring_pass,
    $pg_version,
) {
    ::postgresql::user { "replication@${title}":
        user      => 'replication',
        password  => $replication_pass,
        cidr      => "${ip_address}/32",
        pgversion => $pg_version,
        attrs     => 'REPLICATION',
        database  => 'replication',
    }
    ::postgresql::user { "monitoring@${title}":
        user      => 'monitoring',
        password  => $monitoring_pass,
        cidr      => "${ip_address}/32",
        pgversion => $pg_version,
        database  => 'all',
    }
}

