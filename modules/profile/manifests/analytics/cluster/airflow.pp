# SPDX-License-Identifier: Apache-2.0
# Class: profile::analytics::cluster::airflow
#
# Wrapper profile to include classes needed to
# set up a Airflow instance in the Analytics Cluster.
#
class profile::analytics::cluster::airflow {
    include ::profile::base::production
    include ::profile::base::firewall

    include ::profile::java
    include ::profile::kerberos::client
    include ::profile::kerberos::keytabs

    # Include Hadoop ecosystem client classes.
    require ::profile::hadoop::common
    require ::profile::hive::client

    # We want to exclude spark2 from bullseye installs
    if debian::codename::lt('bullseye') {
        # Spark 2 is manually packaged by us.
        require ::profile::hadoop::spark2
    }

    # Install Spark 3 configuration to be used as a trial with
    # the Spark3 installed with Airflow.
    # Note: this installs conda-analytics package.
    require ::profile::hadoop::spark3

    # Include the configured Airflow instance(s)
    include ::profile::airflow
}
