# @summary manage neutron openvswitch L2 agent
# SPDX-License-Identifier: Apache-2.0
class openstack::neutron::ovs_agent (
    OpenStack::Version                                   $version,
    Stdlib::IP::Address::Nosubnet                        $overlay_address,
    Hash[String[1], OpenStack::Neutron::ProviderNetwork] $provider_networks,
) {
    class { "openstack::neutron::ovs_agent::${version}":
        * => wmflib::resource::filter_params('version'),
    }

    service { 'neutron-openvswitch-agent':
        ensure    => running,
        enable    => true,
        subscribe => [
            File['/etc/neutron/neutron.conf'],
            File['/etc/neutron/plugins/ml2/ml2_conf.ini'],
            # openvswitch_agent.ini uses a notify on the file resource
        ],
    }
}
