class profile::openstack::base::neutron::linuxbridge_agent(
    $version = lookup('profile::openstack::base::version'),
    $bridges = lookup('profile::openstack::base::neutron::bridges'),
    $bridge_mappings = lookup('profile::openstack::base::neutron::bridge_mappings'),
    $physical_interface_mappings = lookup('profile::openstack::base::neutron::physical_interface_mappings'),
    $report_interval = lookup('profile::openstack::base::neutron::report_interval'),
    ) {

    if $::lsbdistcodename == 'buster' {
        # even though the ruleset is managed by neutron using iptables/ebtables, it is actually
        # using nftables. Having the package installed should make much easier to debug stuff.
        # Make sure the service is not running, it would result in a fight with the neutron agent
        class { '::nftables':
            ensure_package => 'present',
            ensure_service => 'absent',
        }
    }

    class {'::openstack::neutron::linuxbridge_agent':
        version                     => $version,
        bridges                     => $bridges,
        bridge_mappings             => $bridge_mappings,
        physical_interface_mappings => $physical_interface_mappings,
        report_interval             => $report_interval,
    }
    contain '::openstack::neutron::linuxbridge_agent'
}
