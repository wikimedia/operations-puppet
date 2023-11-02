# SPDX-License-Identifier: Apache-2.0
class profile::openstack::eqiad1::nova::fullstack::service(
    $osstackcanary_pass = lookup('profile::openstack::eqiad1::nova::fullstack_pass'),
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::eqiad1::openstack_control_nodes'),
    $region = lookup('profile::openstack::eqiad1::region'),
    $network = lookup('profile::openstack::eqiad1::nova::instance_network_id'),
    $puppetmaster = lookup('profile::openstack::eqiad1::puppetmaster_hostname'),
    $bastion_ip = lookup('profile::openstack::eqiad1::nova::fullstack_bastion_ip'),
    ) {

    require ::profile::openstack::eqiad1::clientpackages
    class { '::profile::openstack::base::nova::fullstack::service':
        openstack_control_nodes => $openstack_control_nodes,
        osstackcanary_pass      => $osstackcanary_pass,
        region                  => $region,
        network                 => $network,
        puppetmaster            => $puppetmaster,
        bastion_ip              => $bastion_ip,
        deployment              => 'eqiad1',
    }
}
