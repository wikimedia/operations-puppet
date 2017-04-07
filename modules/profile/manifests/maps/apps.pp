class profile::maps::apps {
    system::role { 'profile::maps::apps':
        ensure      => 'present',
        description => 'Maps Kartotherian / Tilerator server',
    }

    $cassandra_hosts = hiera('cassandra::seeds')
    $cassandra_tilerator_pass = hiera('profile::maps::apps::cassandra_tilerator_pass')
    $pgsql_tilerator_pass = hiera('profile::maps::apps::pgsql_tilerator_pass')
    $cassandra_kartotherian_pass = hiera('profile::maps::apps::cassandra_kartotherian_pass')
    $pgsql_kartotherian_pass = hiera('profile::maps::apps::postgresql_kartotherian_pass')
    $redis_server = hiera('profile::maps::apps::redis_server')
    $conf_sources = hiera('profile::maps::apps::conf_sources')

    class { '::tilerator':
        cassandra_servers        => $cassandra_hosts,
        cassandra_tilerator_pass => $cassandra_tilerator_pass,
        pgsql_tilerator_pass     => $pgsql_tilerator_pass,
        redis_server             => $redis_server,
        conf_sources             => $conf_sources,
    }

    class { 'kartotherian':
        cassandra_servers           => $cassandra_hosts,
        cassandra_kartotherian_pass => $cassandra_kartotherian_pass,
        pgsql_kartotherian_pass     => $pgsql_kartotherian_pass,
        conf_sources                => $conf_sources,
    }

}
