# SPDX-License-Identifier: Apache-2.0

class role::wmcs::cloudlb (
) {
    system::role { $name: }

    include profile::base::production
    include profile::firewall
    include profile::base::cloud_production
    include profile::wmcs::cloud_private_subnet
    include profile::wmcs::cloud_private_subnet::bgp
    include profile::wmcs::cloudlb::haproxy
}
