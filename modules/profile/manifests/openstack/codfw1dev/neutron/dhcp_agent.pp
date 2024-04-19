# SPDX-License-Identifier: Apache-2.0
class profile::openstack::codfw1dev::neutron::dhcp_agent(
    $version = lookup('profile::openstack::codfw1dev::version'),
    $dhcp_domain = lookup('profile::openstack::codfw1dev::nova::dhcp_domain'),
    $report_interval = lookup('profile::openstack::codfw1dev::neutron::report_interval'),
    Boolean $use_ovs = lookup('profile::openstack::codfw1dev::neutron::use_ovs', {default_value => false}),
) {
    require ::profile::openstack::codfw1dev::neutron::common
    class {'profile::openstack::base::neutron::dhcp_agent':
        version         => $version,
        dhcp_domain     => $dhcp_domain,
        report_interval => $report_interval,
        use_ovs         => $use_ovs,
    }
    contain 'profile::openstack::base::neutron::dhcp_agent'
}
