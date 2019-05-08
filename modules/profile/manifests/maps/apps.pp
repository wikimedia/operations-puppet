class profile::maps::apps(
    Array[String] $cassandra_hosts = hiera('profile::cassandra::single_instance::seeds'),
    String $cassandra_kartotherian_pass = hiera('profile::maps::cassandra::kartotherian_pass'),
    String $cassandra_tilerator_pass = hiera('profile::maps::cassandra::tilerator_pass'),
    String $cassandra_tileratorui_pass = hiera('profile::maps::cassandra::tileratorui_pass'),
    String $pgsql_kartotherian_pass = hiera('profile::maps::osm_master::kartotherian_pass'),
    String $pgsql_tilerator_pass = hiera('profile::maps::osm_master::tilerator_pass'),
    String $pgsql_tileratorui_pass = hiera('profile::maps::osm_master::tileratorui_pass'),
    String $redis_server = hiera('profile::maps::apps::redis_server'),
    String $redis_pass = hiera('profile::maps::apps::redis_pass'),
    String $kartotherian_storage_id = hiera('profile::maps::apps::kartotherian_storage_id'),
    String $tilerator_storage_id = hiera('profile::maps::apps::tilerator_storage_id'),
    String $eventlogging_service_uri = hiera('profile::maps::apps::eventlogging_service_uri'),
    Array[String] $sources_to_invalidate = hiera('profile::maps::apps::sources_to_invalidate'),
    String $tile_server_domain = hiera('profile::maps::apps::tile_server_domain'),
    String $wikidata_query_service = hiera('profile::maps::apps::wikidata_query_service'),
    Float[0.0, 1.0] $tilerator_ncpu_ratio = hiera('profile::maps::apps::tilerator_ncpu_ratio'),
) {

    $use_nodejs10 = true

    $contact_groups = 'admins,team-interactive'

    $num_workers = floor($::processorcount * $tilerator_ncpu_ratio)

    class { '::tilerator':
        cassandra_servers        => $cassandra_hosts,
        cassandra_pass           => $cassandra_tilerator_pass,
        pgsql_pass               => $pgsql_tilerator_pass,
        redis_server             => $redis_server,
        redis_pass               => $redis_pass,
        contact_groups           => $contact_groups,
        storage_id               => $tilerator_storage_id,
        eventlogging_service_uri => $eventlogging_service_uri,
        sources_to_invalidate    => $sources_to_invalidate,
        tile_server_domain       => $tile_server_domain,
        num_workers              => $num_workers,
        use_nodejs10             => $use_nodejs10,
    }

    class { '::tilerator::ui':
        cassandra_servers        => $cassandra_hosts,
        cassandra_pass           => $cassandra_tileratorui_pass,
        pgsql_pass               => $pgsql_tileratorui_pass,
        redis_server             => $redis_server,
        redis_pass               => $redis_pass,
        contact_groups           => $contact_groups,
        storage_id               => $tilerator_storage_id,
        eventlogging_service_uri => $eventlogging_service_uri,
        sources_to_invalidate    => $sources_to_invalidate,
        tile_server_domain       => $tile_server_domain,
        use_nodejs10             => $use_nodejs10,
    }

    class { 'kartotherian':
        cassandra_servers      => $cassandra_hosts,
        cassandra_pass         => $cassandra_kartotherian_pass,
        pgsql_pass             => $pgsql_kartotherian_pass,
        contact_groups         => $contact_groups,
        storage_id             => $kartotherian_storage_id,
        tilerator_storage_id   => $tilerator_storage_id,
        wikidata_query_service => $wikidata_query_service,
        use_nodejs10           => $use_nodejs10,
    }

    # those fonts are needed for the new maps style (brighmed)
    ensure_packages(['fonts-noto', 'fonts-noto-cjk'])

    if os_version('debian >= stretch') {
        ensure_packages(['fonts-noto-unhinted'])
    }

}
