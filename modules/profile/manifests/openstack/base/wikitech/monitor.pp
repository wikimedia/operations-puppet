class profile::openstack::base::wikitech::monitor(
    $osm_host = hiera('profile::openstack::base::osm_host'),
    ) {

    # T89323
    monitoring::service { 'wikitech-static-sync':
        description    => 'Wikitech and wt-static content in sync',
        check_command  => 'check_wikitech_static',
        check_interval => 120,
    }

    # T163721
    monitoring::service { 'wikitech-static-version':
        description    => 'Wikitech-static MW version up to date',
        check_command  => 'check_wikitech_static_version',
        check_interval => 720,
    }
}
