# SPDX-License-Identifier: Apache-2.0
# == Class profile::hadoop::worker::clients
#
# Configure a Analytics Hadoop worker node with extra client tools
# to connect to Hive and use Sqoop/Spark2/etc..
#
class profile::hadoop::worker::clients {
    # hive::client is nice to have for jobs launched
    # from random worker nodes as app masters so they
    # have access to hive-site.xml and other hive jars.
    # This installs hive-hcatalog package on worker nodes to get
    # hcatalog jars, including Hive JsonSerde for using
    # JSON backed Hive tables.
    include profile::hive::client

    # Spark 3.1.2 is provided in our custom conda-analytics package
    # via pyspark installed in the conda environment in /opt/conda-analytics.
    include profile::hadoop::spark3

    # Spark 3.5.8 is provided in our custom conda-analytics-next package
    # via pyspark installed in the conda environment in /opt/conda-analytics-next.
    include profile::hadoop::spark35

    # sqoop needs to be on worker nodes if Airflow is to
    # launch sqoop jobs.
    class { 'bigtop::sqoop': }
}
