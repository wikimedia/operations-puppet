# SPDX-License-Identifier: Apache-2.0
class role::openldap::maintenance {
    include profile::base::production
    include profile::firewall
    include profile::openldap::management
}
