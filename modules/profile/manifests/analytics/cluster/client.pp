# SPDX-License-Identifier: Apache-2.0
# == Class profile::analytic::cluster::client
#
# Includes common client classes for working
# with hadoop and other Analytics Cluster services.
#
class profile::analytics::cluster::client {
    require ::profile::analytics::cluster::packages::common

    # Include Hadoop ecosystem client classes.
    require ::profile::hadoop::common
    require ::profile::hive::client

    # This is a Hadoop client, and should
    # have any service system users it needs to
    # interacting with HDFS.
    include ::profile::analytics::cluster::users

    # We want to exclude spark2 from bullseye installs
    if debian::codename::lt('bullseye') {
        # Spark 2 is manually packaged by us, it is not part of CDH.
        require ::profile::hadoop::spark2
    }

    # Install Spark 3 configuration to be used as a trial with
    # the Spark3 installed with Airflow.
    require ::profile::hadoop::spark3

    # These don't require any extra configuration,
    # so no role class is needed.
    class { '::bigtop::sqoop': }
    class { '::bigtop::mahout': }
    class { '::hdfs_tools': }

    include ::profile::analytics::cluster::hdfs_mount

    # Install other useful packages for client nodes.
    # Packages that should exist on both clients and workers
    # belong in the profile::analytics::cluster::packages::common class.
    ensure_packages([
        'kafkacat',
        'jupyter-notebook',
        's-nail',
    ])

    if debian::codename::lt('bullseye') {
    # We continue to support anaconda-wmf until the end of March 2023, by which time
    # all of their functionality should be provided by conda-analytics instead.
    # See https://wikitech.wikimedia.org/wiki/Data_Engineering/Systems/Conda for more details
    # The anaconda-wmf package is therefore to be omitted from bullseye onwards.

        ensure_packages('anaconda-wmf')
    }
}
