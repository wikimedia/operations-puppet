# @summary manage neutron openvswitch L2 agent
# SPDX-License-Identifier: Apache-2.0
class openstack::neutron::ovs_agent (
    OpenStack::Version            $version,
    Stdlib::IP::Address::Nosubnet $overlay_address,
) {
    class { "openstack::neutron::ovs_agent::${version}":
        * => wmflib::resource::filter_params('version'),
    }

    service { 'neutron-openvswitch-agent':
        ensure => running,
        enable => true,
    }
}
