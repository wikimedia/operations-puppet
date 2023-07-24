# SPDX-License-Identifier: Apache-2.0

class role::analytics_cluster::airflow::wmde {
    system::role { 'analytics_cluster::airflow::wmde':
        description => 'Airflow instance for the Wikimedia Deutschland team in the Analytics Cluster',
    }

    include ::profile::analytics::cluster::airflow
}
