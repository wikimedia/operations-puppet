# SPDX-License-Identifier: Apache-2.0

class role::wmcs::cloudlb (
) {
    system::role { $name: }

    include profile::base::production
    include profile::base::firewall
    include profile::wmcs::cloudlb::haproxy
}
