class profile::openstack::base::neutron::metadata_agent(
    $version = hiera('profile::openstack::base::version'),
    $metadata_proxy_shared_secret = hiera('profile::openstack::base::neutron::metadata_proxy_shared_secret'),
    ) {

    class {'::openstack::neutron::metadata_agent':
        version                      => $version,
        metadata_proxy_shared_secret => $metadata_proxy_shared_secret,
    }
    contain '::openstack::neutron::metadata_agent'
}
