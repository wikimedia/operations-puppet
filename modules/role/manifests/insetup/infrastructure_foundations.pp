# SPDX-License-Identifier: Apache-2.0
class role::insetup::infrastructure_foundations {
    include profile::base::production
    include profile::firewall
}
