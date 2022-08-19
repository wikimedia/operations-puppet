# objectstash configuration, for cross-DC ring replication
# Used for the x2 servers which host the mainstash database

class role::mariadb::objectstash {
    system::role { 'mariadb::objectstash':
        description => 'Object stash database',
    }
    include ::profile::base::production
    include ::profile::base::firewall
    include ::role::mariadb::ferm
    include ::profile::mariadb::core
}

# SPDX-License-Identifier: Apache-2.0
