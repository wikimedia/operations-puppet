class profile::openstack::codfw1dev::neutron::metadata_agent(
    $version = lookup('profile::openstack::codfw1dev::version'),
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::codfw1dev::keystone_api_fqdn'),
    $metadata_proxy_shared_secret = lookup('profile::openstack::codfw1dev::neutron::metadata_proxy_shared_secret'),
    $report_interval = lookup('profile::openstack::codfw1dev::neutron::report_interval'),
    ) {

    require ::profile::openstack::codfw1dev::clientpackages
    require ::profile::openstack::codfw1dev::neutron::common
    class {'::profile::openstack::base::neutron::metadata_agent':
        version                      => $version,
        keystone_api_fqdn            => $keystone_api_fqdn,
        metadata_proxy_shared_secret => $metadata_proxy_shared_secret,
        report_interval              => $report_interval,
    }
    contain '::profile::openstack::base::neutron::metadata_agent'
}
