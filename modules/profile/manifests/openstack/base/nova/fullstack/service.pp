# SPDX-License-Identifier: Apache-2.0
class profile::openstack::base::nova::fullstack::service(
    $osstackcanary_pass = lookup('profile::openstack::base::nova::fullstack_pass'),
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::base::openstack_control_nodes'),
    $region = lookup('profile::openstack::base::region'),
    $network = lookup('profile::openstack::base::nova::instance_network_id'),
    $puppetmaster = lookup('profile::openstack::base::puppetmaster_hostname'),
    $bastion_ip = lookup('profile::openstack::base::nova::fullstack_bastion_ip'),
    $deployment = lookup('profile::openstack::base::nova::fullstack_deployment'),
    $_nameservers = lookup('profile::openstack::base::nova::fullstack::nameservers')
    ) {

    $nameservers = $_nameservers.map |$ns| {
        if $ns =~ Stdlib::IP::Address {
            $ns
        } else {
            dnsquery::lookup($ns, true)
        }
    }.flatten.sort

    # We only want this running in one place; just pick the second
    #  host in $openstack_control_nodes.
    $active = $::facts['networking']['fqdn'] == $openstack_control_nodes[1]['host_fqdn']

    class { '::openstack::nova::fullstack::service':
        active       => $active,
        password     => $osstackcanary_pass,
        region       => $region,
        network      => $network,
        puppetmaster => $puppetmaster,
        bastion_ip   => $bastion_ip,
        deployment   => $deployment,
        resolvers    => $nameservers,
    }
    contain '::openstack::nova::fullstack::service'

    if $active {
        class {'::openstack::nova::fullstack::monitor':}
    }
}
