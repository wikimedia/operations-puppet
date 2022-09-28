# SPDX-License-Identifier: Apache-2.0

class profile::openstack::codfw1dev::nova::fullstack::service(
    $osstackcanary_pass = lookup('profile::openstack::codfw1dev::nova::fullstack_pass'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::codfw1dev::openstack_controllers'),
    $region = lookup('profile::openstack::codfw1dev::region'),
    $network = lookup('profile::openstack::codfw1dev::nova::instance_network_id'),
    $puppetmaster = lookup('profile::openstack::codfw1dev::puppetmaster_hostname'),
    $bastion_ip = lookup('profile::openstack::codfw1dev::nova::fullstack_bastion_ip'),
    ) {

    require ::profile::openstack::codfw1dev::clientpackages
    class { '::profile::openstack::base::nova::fullstack::service':
        openstack_controllers => $openstack_controllers,
        osstackcanary_pass    => $osstackcanary_pass,
        region                => $region,
        network               => $network,
        puppetmaster          => $puppetmaster,
        bastion_ip            => $bastion_ip,
    }

    # We only want this running in one place; just pick the first
    #  option in the list.
    if ($::fqdn == $openstack_controllers[0]) {
        class {'::openstack::nova::fullstack::monitor':}
    }
}
