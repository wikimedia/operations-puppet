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
    $kartotherian_storage_id = hiera('profile::maps::apps::kartotherian_storage_id'),
    $tilerator_storage_id = hiera('profile::maps::apps::tilerator_storage_id'),
) {

    $contact_groups = 'admins,team-interactive'

    class { '::tilerator':
        cassandra_servers => $cassandra_hosts,
        cassandra_pass    => $cassandra_tilerator_pass,
        pgsql_pass        => $pgsql_tilerator_pass,
        redis_server      => $redis_server,
        redis_pass        => $redis_pass,
        contact_groups    => $contact_groups,
        storage_id        => $tilerator_storage_id,
    }

    class { '::tilerator::ui':
        cassandra_servers => $cassandra_hosts,
        cassandra_pass    => $cassandra_tileratorui_pass,
        pgsql_pass        => $pgsql_tileratorui_pass,
        redis_server      => $redis_server,
        redis_pass        => $redis_pass,
        contact_groups    => $contact_groups,
        storage_id        => $tilerator_storage_id,
    }

    class { 'kartotherian':
        cassandra_servers    => $cassandra_hosts,
        cassandra_pass       => $cassandra_kartotherian_pass,
        pgsql_pass           => $pgsql_kartotherian_pass,
        contact_groups       => $contact_groups,
        storage_id           => $kartotherian_storage_id,
        tilerator_storage_id => $tilerator_storage_id,
    }

    # those fonts are needed for the new maps style (brighmed)
    ensure_packages(['fonts-noto', 'fonts-noto-cjk'])

    if os_version('debian >= stretch') {
        ensure_packages(['fonts-noto-unhinted'])
    }

}
