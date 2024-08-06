# SPDX-License-Identifier: Apache-2.0
class role::analytics_cluster::postgresql {
    system::role { 'analytics_cluster::postgresql':
        description => 'PostgreSQL cluster for Data Engineering'
    }

    include profile::base::production
    include profile::firewall
    include profile::analytics::postgresql
    include profile::prometheus::postgres_exporter
}
