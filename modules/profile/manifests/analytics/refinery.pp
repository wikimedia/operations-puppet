# == Class profile::analytics::refinery
#
# Includes configuration and resources needed for deploying
# and using the analytics/refinery repository.
#
class profile::analytics::refinery {
    # Make this class depend on hadoop::common configs.  Refinery
    # is intended to work with Hadoop, and many of the
    # role classes here use the hdfs user, which is created
    # by the CDH packages.
    require ::profile::hadoop::common

    require ::profile::analytics::cluster::packages::hadoop

    require ::profile::analytics::refinery::repository

    # Required by a lot of profiles dependent on this one
    # to find the correct path for scripts etc..
    $path = $::profile::analytics::refinery::repository::path
    $log_dir = $::profile::analytics::refinery::repository::log_dir

    # Clone mediawiki/event-schemas so refinery can use them.
    class { '::eventschemas': }
}
