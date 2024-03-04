# @summary manage neutron openvswitch L2 agent
# SPDX-License-Identifier: Apache-2.0
class profile::openstack::base::neutron::ovs_agent (
    OpenStack::Version $version = lookup('profile::openstack::base::version'),
) {
    class { 'openvswitch': }

    class { 'openstack::neutron::ovs_agent':
        *               => wmflib::resource::dump_params(),
        overlay_address => $profile::wmcs::cloud_private_subnet::cloud_private_address,
    }
}
