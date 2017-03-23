# == Class role::analytic_cluster::client
# Includes common client classes for working
# with hadoop and other Analytics Cluster services.
#
class role::analytics_cluster::client {
    system::role { 'analytics_cluster::client':
        description => 'Client node for interacting with the Analytics Cluster',
    }

    # Include Wikimedia's thirdparty/cloudera apt component
    # as an apt source on all Hadoop hosts.  This is needed
    # to install CDH packages from our apt repo mirror.
    require ::role::analytics_cluster::apt

    # Include Hadoop ecosystem client classes.
    require ::role::analytics_cluster::hadoop::client
    require ::role::analytics_cluster::hive::client
    require ::role::analytics_cluster::oozie::client
    # These don't require any extra configuration,
    # so no role class is needed.
    require ::cdh::pig
    require ::cdh::sqoop
    require ::cdh::mahout
    require ::cdh::spark

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