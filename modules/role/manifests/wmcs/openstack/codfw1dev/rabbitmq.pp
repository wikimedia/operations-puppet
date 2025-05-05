# SPDX-License-Identifier: Apache-2.0
class role::wmcs::openstack::codfw1dev::rabbitmq {
    include profile::base::production
    include profile::firewall
    include profile::base::cloud_production
    include profile::wmcs::cloud_private_subnet

    include profile::openstack::codfw1dev::rabbitmq
}
