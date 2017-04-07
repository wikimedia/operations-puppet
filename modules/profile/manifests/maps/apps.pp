class profile::maps::apps {
    system::role { 'profile::maps::apps':
        ensure      => 'present',
        description => 'Maps Kartotherian / Tilerator server',
    }

    include ::tilerator

    $cassandra_hosts = hiera('cassandra::seeds')

    class { 'kartotherian':
        cassandra_servers           => $cassandra_hosts,
        cassandra_kartotherian_pass => hiera('maps::cassandra_kartotherian_pass'),
        pgsql_kartotherian_pass     => hiera('maps::postgresql_kartotherian_pass'),
    }

}