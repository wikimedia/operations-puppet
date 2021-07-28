class role::analytics_cluster::airflow::research {
    system::role { 'analytics_cluster::airflow::research':
        description => 'Airflow instance for the Research team in the Analytics Cluster',
    }

    # TODO: uncomment this when ready - T284225
    include ::profile::airflow

    include ::profile::standard
    include ::profile::base::firewall

    include ::profile::java
    include ::profile::kerberos::client
    include ::profile::kerberos::keytabs

    # Include Hadoop ecosystem client classes.
    require ::profile::hadoop::common
    require ::profile::hive::client

    # Spark 2 is manually packaged by us.
    require ::profile::hadoop::spark2
}
