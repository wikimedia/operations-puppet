# SPDX-License-Identifier: Apache-2.0
# @summary Cloud VPS OpenStack L3 router (Open vSwitch)
class role::wmcs::openstack::eqiad1::net_ovs {
    include profile::base::production
    include profile::base::no_firewall
    include profile::base::cloud_production
    include profile::wmcs::cloud_private_subnet

    include profile::openstack::eqiad1::clientpackages
    include profile::openstack::eqiad1::observerenv
    include profile::openstack::eqiad1::neutron::common
    include profile::openstack::eqiad1::neutron::l3_agent
    include profile::openstack::eqiad1::neutron::dhcp_agent
    include profile::openstack::eqiad1::neutron::metadata_agent
    include profile::wmcs::services::oidentd::proxy
}
