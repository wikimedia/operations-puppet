class profile::maps::apps(
    $cassandra_hosts = hiera('profile::cassandra::single_instance::seeds'),
    $cassandra_kartotherian_pass = hiera('profile::maps::cassandra::kartotherian_pass'),
    $cassandra_tilerator_pass = hiera('profile::maps::cassandra::tilerator_pass'),
    $cassandra_tileratorui_pass = hiera('profile::maps::cassandra::tileratorui_pass'),
    $pgsql_kartotherian_pass = hiera('profile::maps::osm_master::kartotherian_pass'),
    $pgsql_tilerator_pass = hiera('profile::maps::osm_master::tilerator_pass'),
    $pgsql_tileratorui_pass = hiera('profile::maps::osm_master::tileratorui_pass'),
    $redis_server = hiera('profile::maps::apps::redis_server'),
    $conf_sources = hiera('profile::maps::apps::conf_sources'),
    $storage_id = hiera('profile::maps::apps::storage_id'),
) {


    $contact_groups = 'admins,team-interactive'

    class { '::tilerator':
        cassandra_servers => $cassandra_hosts,
        cassandra_pass    => $cassandra_tilerator_pass,
        pgsql_pass        => $pgsql_tilerator_pass,
        redis_server      => $redis_server,
        conf_sources      => $conf_sources,
        contact_groups    => $contact_groups,
    }

    class { '::tilerator::ui':
        cassandra_servers => $cassandra_hosts,
        cassandra_pass    => $cassandra_tileratorui_pass,
        pgsql_pass        => $pgsql_tileratorui_pass,
        redis_server      => $redis_server,
        conf_sources      => $conf_sources,
        contact_groups    => $contact_groups,
        storage_id        => $storage_id,
        require           => Class['::tilerator'],
    }

    class { 'kartotherian':
        cassandra_servers => $cassandra_hosts,
        cassandra_pass    => $cassandra_kartotherian_pass,
        pgsql_pass        => $pgsql_kartotherian_pass,
        conf_sources      => $conf_sources,
        contact_groups    => $contact_groups,
    }

}
