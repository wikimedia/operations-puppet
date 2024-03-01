# SPDX-License-Identifier: Apache-2.0
# @summary Cloud VPS OpenStack L3 router (Open vSwitch testing)
class role::wmcs::openstack::codfw1dev::net_ovs () {
  include profile::base::production
  include profile::base::no_firewall
  include profile::base::cloud_production
  include profile::wmcs::cloud_private_subnet
}
