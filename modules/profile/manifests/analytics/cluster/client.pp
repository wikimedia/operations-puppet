# == Class profile::analytic::cluster::client
#
# Includes common client classes for working
# with hadoop and other Analytics Cluster services.
#
class profile::analytics::cluster::client(
    $monitoring_enabled = hiera('profile::analytics::cluster::client::monitoring_enabled', true),
) {
    require ::profile::analytics::cluster::packages::hadoop

    # Include Hadoop ecosystem client classes.
    require ::profile::hadoop::common
    require ::profile::hive::client
    require ::profile::oozie::client

    # Spark 2 is manually packaged by us, it is not part of CDH.
    require ::profile::hadoop::spark2

    # These don't require any extra configuration,
    # so no role class is needed.
    class { '::cdh::pig': }
    class { '::cdh::sqoop': }
    class { '::cdh::mahout': }

    # Mount HDFS via Fuse on Analytics client nodes.
    # This will mount HDFS at /mnt/hdfs read only.
    class { '::cdh::hadoop::mount': }

    if $monitoring_enabled {
        file { '/usr/local/lib/nagios/plugins/check_mountpoint_readability':
            ensure => present,
            source => 'puppet:///modules/profile/analytics/check_mountpoint_readability',
            mode   => '0555',
            owner  => 'root',
            group  => 'root',
        }
        nrpe::monitor_service { 'check_hadoop_mount_readability':
            description    => 'Check if the Hadoop HDFS Fuse mountpoint is readable',
            nrpe_command   => "/usr/local/lib/nagios/plugins/check_mountpoint_readability ${cdh::hadoop::mount::mount_point}",
            check_interval => 30,
            retries        => 2,
            contact_group  => 'analytics',
            require        => File['/usr/local/lib/nagios/plugins/check_mountpoint_readability'],
        }
    }

    # Install other useful packages for client nodes.
    # Packages that should exist on both clients and workers
    # belong in the profile::analytics::cluster::packages::hadoop class.
    require_package(
        'kafkacat',
        'heirloom-mailx',
        'jupyter-notebook',
    )
}