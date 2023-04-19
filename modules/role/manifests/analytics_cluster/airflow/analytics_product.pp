# SPDX-License-Identifier: Apache-2.0

class role::analytics_cluster::airflow::analytics_product {
    system::role { 'analytics_cluster::airflow::analytics_product':
        description => 'Airflow instance for the Product Analytics team in the Analytics Cluster',
    }

    include ::profile::analytics::cluster::airflow
}
