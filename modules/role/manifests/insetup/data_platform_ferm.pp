# SPDX-License-Identifier: Apache-2.0
class role::insetup::data_platform_ferm {
    include profile::base::production
    include profile::firewall
}
