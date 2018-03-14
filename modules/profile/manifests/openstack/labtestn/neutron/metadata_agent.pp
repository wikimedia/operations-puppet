class profile::openstack::labtestn::neutron::metadata_agent(
    $version = hiera('profile::openstack::labtestn::version'),
    $metadata_proxy_shared_secret = heira('profile::openstack::labtestn::neutron::metadata_proxy_shared_secret'),
    ) {

    require ::profile::openstack::labtestn::clientlib
    require ::profile::openstack::labtestn::neutron::common
    class {'::profile::openstack::base::neutron::metadata_agent':
        version                      => $version,
        metadata_proxy_shared_secret => $metadata_proxy_shared_secret,
    }
    contain '::profile::openstack::base::neutron::metadata_agent'
}
