# SPDX-License-Identifier: Apache-2.0

class role::idmcloud {
    include profile::base::production
    include profile::firewall
    include profile::idm
}
