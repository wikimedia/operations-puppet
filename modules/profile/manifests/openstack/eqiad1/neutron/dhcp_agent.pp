class profile::openstack::eqiad1::neutron::dhcp_agent(
    $version = lookup('profile::openstack::eqiad1::version'),
    $dhcp_domain = lookup('profile::openstack::eqiad1::nova::dhcp_domain'),
    $report_interval = lookup('profile::openstack::eqiad1::neutron::report_interval'),
    Boolean $use_ovs = lookup('profile::openstack::eqiad1::neutron::use_ovs', {default_value => false}),
    ) {

    require ::profile::openstack::eqiad1::clientpackages
    require ::profile::openstack::eqiad1::neutron::common
    class {'profile::openstack::base::neutron::dhcp_agent':
        version         => $version,
        dhcp_domain     => $dhcp_domain,
        report_interval => $report_interval,
        use_ovs         => $use_ovs,
    }
    contain 'profile::openstack::base::neutron::dhcp_agent'
}
