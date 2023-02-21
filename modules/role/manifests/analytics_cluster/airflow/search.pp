# SPDX-License-Identifier: Apache-2.0

class role::analytics_cluster::airflow::search {
    system::role { 'analytics_cluster::airflow::search':
        description => 'Airflow instance for the Search Platform team in the Analytics Cluster',
    }

    include ::profile::analytics::cluster::airflow
    include ::profile::analytics::refinery
}
