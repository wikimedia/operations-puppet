# SPDX-License-Identifier: Apache-2.0
# == Class profile::analytic::cluster::client
#
# Includes common client classes for working
# with hadoop and other Analytics Cluster services.
#
class profile::analytics::cluster::client {
    require profile::analytics::cluster::packages::common

    # Include Hadoop ecosystem client classes.
    require profile::hadoop::common
    require profile::hive::client

    # This is a Hadoop client, and should
    # have any service system users it needs to
    # interacting with HDFS.
    include profile::analytics::cluster::users

    # Spark 3.1.2 is provided in our custom conda-analytics package
    # via pyspark installed in the conda environment in /opt/conda-analytics.
    include profile::hadoop::spark3

    # Spark 3.5.8 is provided in our custom conda-analytics-next package
    # via pyspark installed in the conda environment in /opt/conda-analytics-next.
    include profile::hadoop::spark35

    # These don't require any extra configuration,
    # so no role class is needed.
    class { 'bigtop::sqoop': }
    class { 'bigtop::mahout': }
    class { 'hdfs_tools': }

    include profile::analytics::cluster::hdfs_mount

    # Install other useful packages for client nodes.
    # Packages that should exist on both clients and workers
    # belong in the profile::analytics::cluster::packages::common class.
    if debian::codename::ge('bookworm') {
        ensure_packages('kcat')
    } else {
        ensure_packages('kafkacat')
    }
    ensure_packages([
            'jupyter-notebook',
            's-nail',
    ])
}
