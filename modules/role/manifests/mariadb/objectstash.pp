# SPDX-License-Identifier: Apache-2.0
# objectstash configuration, for cross-DC ring replication
# Used for the x2 servers which host the mainstash database

class role::mariadb::objectstash {
    include profile::base::production
    include profile::firewall
    include role::mariadb::ferm
    include profile::mariadb::core
}
