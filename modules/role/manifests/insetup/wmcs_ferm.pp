# SPDX-License-Identifier: Apache-2.0
class role::insetup::wmcs_ferm {
    include profile::base::production
    include profile::firewall
    include profile::base::cloud_production
}
