# SPDX-License-Identifier: Apache-2.0
# @summary manage neutron openvswitch L2 agent
# @param version OpenStack version in use
# @param bridge_mappings openstack provider networks
class profile::openstack::base::neutron::ovs_agent (
    OpenStack::Version                                   $version           = lookup('profile::openstack::base::version'),
    Hash[String[1], OpenStack::Neutron::ProviderNetwork] $provider_networks = lookup('profile::openstack::base::neutron::physical_interface_mappings'),
) {
    class { 'openvswitch': }

    $provider_networks.each |String[1] $network, OpenStack::Neutron::ProviderNetwork $config| {
        openvswitch::bridge { $config['bridge']: }
        openvswitch::bridge::member { $config['interface']:
            bridge => $config['bridge'],
        }
    }

    class { 'openstack::neutron::ovs_agent':
        *               => wmflib::resource::dump_params(),
        overlay_address => $profile::wmcs::cloud_private_subnet::cloud_private_address,
    }
}
