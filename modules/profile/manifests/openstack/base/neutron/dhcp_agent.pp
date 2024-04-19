class profile::openstack::base::neutron::dhcp_agent(
    $version = lookup('profile::openstack::base::version'),
    $dhcp_domain = lookup('profile::openstack::base::nova::dhcp_domain'),
    $report_interval = lookup('profile::openstack::base::neutron::report_interval'),
    Boolean $use_ovs = lookup('profile::openstack::base::neutron::use_ovs', {default_value => false}),
) {
    class {'::openstack::neutron::dhcp_agent':
        version          => $version,
        dhcp_domain      => $dhcp_domain,
        report_interval  => $report_interval,
        interface_driver => $use_ovs.bool2str('openvswitch', 'linuxbridge'),
    }
    contain '::openstack::neutron::dhcp_agent'
}
