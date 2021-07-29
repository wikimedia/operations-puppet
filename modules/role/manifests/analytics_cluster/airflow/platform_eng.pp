class role::analytics_cluster::airflow::platform_eng {
    system::role { 'analytics_cluster::airflow::platform_eng':
        description => 'Airflow instance for the Platform Engineering team in the Analytics Cluster',
    }

    include ::profile::analytics::cluster::airflow
}
