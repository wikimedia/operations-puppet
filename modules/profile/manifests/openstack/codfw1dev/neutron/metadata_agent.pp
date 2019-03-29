class profile::openstack::codfw1dev::neutron::metadata_agent(
    $version = hiera('profile::openstack::codfw1dev::version'),
    $nova_controller = hiera('profile::openstack::codfw1dev::nova_controller'),
    $metadata_proxy_shared_secret = hiera('profile::openstack::codfw1dev::neutron::metadata_proxy_shared_secret'),
    $report_interval = hiera('profile::openstack::codfw1dev::neutron::report_interval'),
    ) {

    require ::profile::openstack::codfw1dev::clientpackages
    require ::profile::openstack::codfw1dev::neutron::common
    class {'::profile::openstack::base::neutron::metadata_agent':
        version                      => $version,
        nova_controller              => $nova_controller,
        metadata_proxy_shared_secret => $metadata_proxy_shared_secret,
        report_interval              => $report_interval,
    }
    contain '::profile::openstack::base::neutron::metadata_agent'
}
