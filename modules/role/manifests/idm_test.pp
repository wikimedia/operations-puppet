# SPDX-License-Identifier: Apache-2.0

class role::idm_test {
    include profile::base::production
    include profile::firewall
    include profile::idm
}
