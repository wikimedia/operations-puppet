class profile::openstack::main::wikitech::monitor(
    $osm_host = hiera('profile::openstack::main::osm_host'),
    ) {

    class {'::profile::openstack::base::wikitech::monitor':
        osm_host => osm_host,
    }
}
