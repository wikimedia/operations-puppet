class profile::openstack::labtest::wikitech::monitor(
    $osm_host = hiera('profile::openstack::labtest::osm_host'),
    ) {

    class {'::profile::openstack::base::wikitech::monitor':
        osm_host => $osm_host,
    }
}
