class profile::maps::apps(
    String $osm_engine = lookup('profile::maps::osm_master::engine', { 'default_value' => 'osm2pgsql' }),
    Array[String] $cassandra_hosts = lookup('profile::cassandra::single_instance::seeds'),
    String $cassandra_kartotherian_pass = lookup('profile::maps::cassandra::kartotherian_pass'),
    String $cassandra_tilerator_pass = lookup('profile::maps::cassandra::tilerator_pass'),
    String $cassandra_tileratorui_pass = lookup('profile::maps::cassandra::tileratorui_pass'),
    String $pgsql_kartotherian_pass = lookup('profile::maps::osm_master::kartotherian_pass'),
    String $pgsql_tilerator_pass = lookup('profile::maps::osm_master::tilerator_pass'),
    String $pgsql_tileratorui_pass = lookup('profile::maps::osm_master::tileratorui_pass'),
    String $redis_server = lookup('profile::maps::apps::redis_server'),
    String $redis_pass = lookup('profile::maps::apps::redis_pass'),
    String $kartotherian_storage_id = lookup('profile::maps::apps::kartotherian_storage_id'),
    String $tilerator_storage_id = lookup('profile::maps::apps::tilerator_storage_id'),
    String $wikidata_query_service = lookup('profile::maps::apps::wikidata_query_service'),
    Float[0.0, 1.0] $tilerator_ncpu_ratio = lookup('profile::maps::apps::tilerator_ncpu_ratio'),
    Boolean $tilerator_enable = lookup('profile::maps::apps::tilerator_enable'),
) {

    $osm_dir = $osm_engine ? {
        'osm2pgsql' => '/srv/osmosis',
        'imposm3' => '/srv/osm'
    }

    $contact_groups = 'admins,team-interactive'

    $num_workers = floor($::processorcount * $tilerator_ncpu_ratio)

    class { '::tilerator':
        cassandra_servers => $cassandra_hosts,
        cassandra_pass    => $cassandra_tilerator_pass,
        pgsql_pass        => $pgsql_tilerator_pass,
        redis_server      => $redis_server,
        redis_pass        => $redis_pass,
        contact_groups    => $contact_groups,
        storage_id        => $tilerator_storage_id,
        num_workers       => $num_workers,
        enable            => $tilerator_enable
    }

    class { '::tilerator::ui':
        cassandra_servers => $cassandra_hosts,
        cassandra_pass    => $cassandra_tileratorui_pass,
        pgsql_pass        => $pgsql_tileratorui_pass,
        redis_server      => $redis_server,
        redis_pass        => $redis_pass,
        contact_groups    => $contact_groups,
        storage_id        => $tilerator_storage_id,
        osm_dir           => $osm_dir
    }

    class { 'kartotherian':
        cassandra_servers      => $cassandra_hosts,
        cassandra_pass         => $cassandra_kartotherian_pass,
        pgsql_pass             => $pgsql_kartotherian_pass,
        contact_groups         => $contact_groups,
        storage_id             => $kartotherian_storage_id,
        tilerator_storage_id   => $tilerator_storage_id,
        wikidata_query_service => $wikidata_query_service,
    }

    # those fonts are needed for the new maps style (brighmed)
    ensure_packages(['fonts-noto', 'fonts-noto-cjk', 'fonts-noto-unhinted'])
}
