# SPDX-License-Identifier: Apache-2.0
# Writable LDAP servers (based on OpenLDAP) using MDB as storage backend
class role::openldap::rw_mdb {
    include profile::base::production
    include profile::firewall
    include profile::backup::host
    include profile::openldap
}
