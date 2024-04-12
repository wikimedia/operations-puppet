# SPDX-License-Identifier: Apache-2.0
class role::insetup::unowned {
    include profile::base::production
    include profile::firewall
}
