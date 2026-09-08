# SPDX-License-Identifier: Apache-2.0
# Read-only LDAP servers (based on OpenLDAP) using MDB as storage backend
class role::openldap::replica_mdb {
    include profile::base::production
    include profile::firewall
    include profile::openldap
    include profile::lvs::realserver
    include profile::lvs::realserver::ipip
}
