# Create users for PostgreSQL Replication / Monitoring
# This inner define should probably be replaced by iterator once we activate future parser
define postgresql::slave_users(
    $ip_address,
    $replication_pass,
) {
    ::postgresql::user { "replication@${title}":
        user     => 'replication',
        password => $replication_pass,
        cidr     => "${ip_address}/32",
        attrs    => 'REPLICATION',
        database => 'replication',
    }
    ::postgresql::user { "monitoring@${title}":
        user     => 'replication',
        password => $replication_pass,
        cidr     => "${ip_address}/32",
        database => 'template1',
    }
}

