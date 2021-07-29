class role::analytics_cluster::airflow::research {
    system::role { 'analytics_cluster::airflow::research':
        description => 'Airflow instance for the Research team in the Analytics Cluster',
    }

    include ::profile::analytics::cluster::airflow
}
