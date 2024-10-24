# SPDX-License-Identifier: Apache-2.0
class openstack::neutron::ovs_agent::bobcat (
    Stdlib::IP::Address::Nosubnet                        $overlay_address,
    Hash[String[1], OpenStack::Neutron::ProviderNetwork] $provider_networks,
) {
    require "openstack::serverpackages::bobcat::${debian::codename()}"

    package { 'neutron-openvswitch-agent':
        ensure => 'present',
    }

    file { '/etc/neutron/plugins/ml2/openvswitch_agent.ini':
        owner   => 'neutron',
        group   => 'neutron',
        mode    => '0640',
        content => template('openstack/bobcat/neutron/plugins/ml2/openvswitch_agent.ini.erb'),
        require => Package['neutron-openvswitch-agent'],
        notify  => Service['neutron-openvswitch-agent'],
    }
}
