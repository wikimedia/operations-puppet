class profile::openstack::eqiad1::neutron::metadata_agent(
    $version = hiera('profile::openstack::eqiad1::version'),
    $nova_controller = hiera('profile::openstack::eqiad1::nova_controller'),
    $metadata_proxy_shared_secret = hiera('profile::openstack::eqiad1::neutron::metadata_proxy_shared_secret'),
    $report_interval = hiera('profile::openstack::eqiad1::neutron::report_interval'),
    ) {

    require ::profile::openstack::eqiad1::clientlib
    require ::profile::openstack::eqiad1::neutron::common
    class {'::profile::openstack::base::neutron::metadata_agent':
        version                      => $version,
        nova_controller              => $nova_controller,
        metadata_proxy_shared_secret => $metadata_proxy_shared_secret,
        report_interval              => $report_interval,
    }
    contain '::profile::openstack::base::neutron::metadata_agent'
}
