class profile::openstack::labtestn::neutron::metadata_agent(
    $version = hiera('profile::openstack::labtestn::version'),
    $nova_controller = hiera('profile::openstack::labtestn::nova_controller'),
    $metadata_proxy_shared_secret = hiera('profile::openstack::labtestn::neutron::metadata_proxy_shared_secret'),
    $report_interval = hiera('profile::openstack::labtestn::neutron::report_interval'),
    ) {

    require ::profile::openstack::labtestn::clientpackages
    require ::profile::openstack::labtestn::neutron::common
    class {'::profile::openstack::base::neutron::metadata_agent':
        version                      => $version,
        nova_controller              => $nova_controller,
        metadata_proxy_shared_secret => $metadata_proxy_shared_secret,
        report_interval              => $report_interval,
    }
    contain '::profile::openstack::base::neutron::metadata_agent'
}
