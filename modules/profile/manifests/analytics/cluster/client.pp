# == Class profile::analytics::cluster::client
#
# Includes common client classes for working
# with Hadoop and other Analytics Cluster services.
#
class profile::analytics::cluster::client {

    # Include Hadoop ecosystem client classes.
    require ::profile::hadoop::client
    require ::profile::hive::client
    require ::profile::oozie::client

    # These don't require any extra configuration,
    # so no role class is needed.
    class { '::cdh::pig': }
    class { '::cdh::sqoop': }
    class { '::cdh::mahout': }
    class { '::cdh::spark': }

    # Spark 2 is manually packaged by us, it is not part of CDH.
    require_package('spark2')

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
    class { '::maven': }
}