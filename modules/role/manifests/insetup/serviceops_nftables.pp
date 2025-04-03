# SPDX-License-Identifier: Apache-2.0
class role::insetup::serviceops_nftables {
    include profile::base::production
    include profile::firewall
}
