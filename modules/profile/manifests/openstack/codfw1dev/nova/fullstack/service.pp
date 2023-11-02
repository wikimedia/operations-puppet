# SPDX-License-Identifier: Apache-2.0

class profile::openstack::codfw1dev::nova::fullstack::service(
    $osstackcanary_pass = lookup('profile::openstack::codfw1dev::nova::fullstack_pass'),
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::codfw1dev::openstack_control_nodes'),
    $region = lookup('profile::openstack::codfw1dev::region'),
    $network = lookup('profile::openstack::codfw1dev::nova::instance_network_id'),
    $puppetmaster = lookup('profile::openstack::codfw1dev::puppetmaster_hostname'),
    $bastion_ip = lookup('profile::openstack::codfw1dev::nova::fullstack_bastion_ip'),
    ) {

    require ::profile::openstack::codfw1dev::clientpackages
    class { '::profile::openstack::base::nova::fullstack::service':
        openstack_control_nodes => $openstack_control_nodes,
        osstackcanary_pass      => $osstackcanary_pass,
        region                  => $region,
        network                 => $network,
        puppetmaster            => $puppetmaster,
        bastion_ip              => $bastion_ip,
        deployment              => 'codfw1dev',
    }
}
