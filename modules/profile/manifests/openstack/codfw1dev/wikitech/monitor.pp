class profile::openstack::codfw1dev::wikitech::monitor(
    $osm_host = lookup('profile::openstack::codfw1dev::osm_host'),
    ) {

    class {'::profile::openstack::base::wikitech::monitor':
        osm_host => $osm_host,
    }
}
