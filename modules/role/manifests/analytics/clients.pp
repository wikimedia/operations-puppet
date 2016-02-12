# == Class role::analytics::clients
# Includes common client classes for
# working with hadoop and other analytics services.
class role::analytics::clients {
    include role::analytics

    # Include Hadoop ecosystem client classes.
    include role::analytics::hadoop::client,
        role::analytics::hive::client,
        role::analytics::oozie::client,
        role::analytics::pig,
        role::analytics::sqoop,
        role::analytics::mahout,
        role::analytics::spark

    # Mount HDFS via Fuse on Analytics client nodes.
    # This will mount HDFS at /mnt/hdfs read only.
    class { 'cdh::hadoop::mount':
        # Make sure this package is removed before
        # cdh::hadoop::mount evaluates.
        require => Package['icedtea-7-jre-jamvm'],
    }

    # These packages are useful, install them.
    ensure_packages([
        'ipython-notebook',
        'kafkacat',
    ])

    # include maven to build jars for Hadoop.
    include ::maven
}
