# Class: profile::analytics::cluster::airflow
#
# Wrapper profile to include classes needed to
# set up a Airflow instance in the Analytics Cluster.
#
class profile::analytics::cluster::airflow {
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

    # Include the configured Airflow instance(s)
    include ::profile::airflow
}
