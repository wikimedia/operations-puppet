# == Class role::analytic_cluster::client
# Includes common client classes for working
# with hadoop and other Analytics Cluster services.
#
class role::analytics_cluster::client {
    system::role { 'analytics_cluster::client':
        description => 'Client node for interacting with the Analytics Cluster',
    }

    # Include Hadoop ecosystem client classes.
    require ::profile::hadoop::common
    require ::profile::hive::client
    require ::profile::oozie::client

    # Spark 2 is manually packaged by us, it is not part of CDH.
    require ::profile::hadoop::spark2

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
        'kafkacat',
        'heirloom-mailx',
        'python-docopt',
        'python3-docopt',
        # Really nice pure python hdfs client
        'snakebite',
    )

    if os_version('debian >= stretch') {
        require_package('jupyter-notebook')
    }
    else {
        require_package('ipython-notebook')
    }

    # include maven to build jars for Hadoop.
    include ::maven
}