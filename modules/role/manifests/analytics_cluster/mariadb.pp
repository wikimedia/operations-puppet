# SPDX-License-Identifier: Apache-2.0
class role::analytics_cluster::mariadb {
    system::role { 'analytics_cluster::mariadb':
        description => 'MariaDB cluster for Data Engineering',
    }

    include profile::base::production
    include profile::firewall
    include profile::analytics::database::meta
}
