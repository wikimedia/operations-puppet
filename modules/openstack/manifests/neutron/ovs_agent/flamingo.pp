# SPDX-License-Identifier: Apache-2.0
class openstack::neutron::ovs_agent::flamingo (
    Stdlib::IP::Address::Nosubnet                        $overlay_address,
    Hash[String[1], OpenStack::Neutron::ProviderNetwork] $provider_networks,
) {
    package { 'neutron-openvswitch-agent':
        ensure => 'present',
    }

    file { '/etc/neutron/plugins/ml2/openvswitch_agent.ini':
        owner   => 'neutron',
        group   => 'neutron',
        mode    => '0640',
        content => template('openstack/flamingo/neutron/plugins/ml2/openvswitch_agent.ini.erb'),
        require => Package['neutron-openvswitch-agent'],
        # NOTE: not notifying the service on file changes, see T380972
    }
}
