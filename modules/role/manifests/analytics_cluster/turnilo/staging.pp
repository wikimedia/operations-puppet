# SPDX-License-Identifier: Apache-2.0
# Class: role::analytics_cluster::turnilo::staging
#
class role::analytics_cluster::turnilo::staging {
    system::role { 'analytics_cluster::turnilo::staging':
        description => 'Turnilo web GUI for Druid (staging environment)'
    }

    include ::profile::druid::turnilo
    include ::profile::base::firewall
    include ::profile::base::production
}
