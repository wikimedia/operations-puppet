class profile::openstack::eqiad1::neutron::metadata_agent(
    $version = lookup('profile::openstack::eqiad1::version'),
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::eqiad1::keystone_api_fqdn'),
    $metadata_proxy_shared_secret = lookup('profile::openstack::eqiad1::neutron::metadata_proxy_shared_secret'),
    $report_interval = lookup('profile::openstack::eqiad1::neutron::report_interval'),
    ) {

    require ::profile::openstack::eqiad1::clientpackages
    require ::profile::openstack::eqiad1::neutron::common
    class {'::profile::openstack::base::neutron::metadata_agent':
        version                      => $version,
        keystone_api_fqdn            => $keystone_api_fqdn,
        metadata_proxy_shared_secret => $metadata_proxy_shared_secret,
        report_interval              => $report_interval,
    }
    contain '::profile::openstack::base::neutron::metadata_agent'
}
