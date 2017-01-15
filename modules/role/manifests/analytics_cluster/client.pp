# == Class role::analytic_cluster::client
# Includes common client classes for working
# with hadoop and other Analytics Cluster services.
#
class role::analytics_cluster::client {
    system::role { 'analytics_cluster::client':
        description => 'Client node for interacting with the Analytics Cluster',
    }

    # Include Hadoop ecosystem client classes.
    require ::role::analytics_cluster::hadoop::client,
        role::analytics_cluster::hive::client,
        role::analytics_cluster::oozie::client,
        # These don't require any extra configuration,
        # so no role class is needed.
        cdh::pig,
        cdh::sqoop,
        cdh::mahout,
        cdh::spark

    # Mount HDFS via Fuse on Analytics client nodes.
    # This will mount HDFS at /mnt/hdfs read only.
    class { '::cdh::hadoop::mount': }

    # These packages are useful, install them.
    require_package(
        'ipython-notebook',
        'kafkacat',
        'heirloom-mailx',
        'python-docopt',
        'python3-docopt',
        # Really nice pure python hdfs client
        'snakebite',
    )

    # include maven to build jars for Hadoop.
    include ::maven
}