class profile::maps::apps(
    $cassandra_hosts = hiera('profile::cassandra::single_instance::seeds'),
    $cassandra_kartotherian_pass = hiera('profile::maps::cassandra::kartotherian_pass'),
    $cassandra_tilerator_pass = hiera('profile::maps::cassandra::tilerator_pass'),
    $cassandra_tileratorui_pass = hiera('profile::maps::cassandra::tileratorui_pass'),
    $pgsql_kartotherian_pass = hiera('profile::maps::osm_master::kartotherian_pass'),
    $pgsql_tilerator_pass = hiera('profile::maps::osm_master::tilerator_pass'),
    $pgsql_tileratorui_pass = hiera('profile::maps::osm_master::tileratorui_pass'),
    $redis_server = hiera('profile::maps::apps::redis_server'),
    $redis_pass = hiera('profile::maps::apps::redis_pass'),
) {

    $conf_sources = 'sources.prod2.yaml'
    $storage_id = 'v3'


    $contact_groups = 'admins,team-interactive'

    profile::maps::sources_config { 'kartotherian':
        mode       => 'kartotherian',
        storage_id => $storage_id,
    }
    profile::maps::sources_config { 'tilerator':
        mode       => 'tilerator',
        storage_id => $storage_id,
    }
    profile::maps::sources_config { 'tileratorui':
        mode       => 'tilerator',
        storage_id => $storage_id,
    }

    class { '::tilerator':
        cassandra_servers => $cassandra_hosts,
        cassandra_pass    => $cassandra_tilerator_pass,
        pgsql_pass        => $pgsql_tilerator_pass,
        redis_server      => $redis_server,
        redis_pass        => $redis_pass,
        conf_sources      => $conf_sources,
        contact_groups    => $contact_groups,
    }

    class { '::tilerator::ui':
        cassandra_servers => $cassandra_hosts,
        cassandra_pass    => $cassandra_tileratorui_pass,
        pgsql_pass        => $pgsql_tileratorui_pass,
        redis_server      => $redis_server,
        redis_pass        => $redis_pass,
        conf_sources      => $conf_sources,
        contact_groups    => $contact_groups,
        storage_id        => $storage_id,
    }

    class { 'kartotherian':
        cassandra_servers => $cassandra_hosts,
        cassandra_pass    => $cassandra_kartotherian_pass,
        pgsql_pass        => $pgsql_kartotherian_pass,
        conf_sources      => $conf_sources,
        contact_groups    => $contact_groups,
    }

}
