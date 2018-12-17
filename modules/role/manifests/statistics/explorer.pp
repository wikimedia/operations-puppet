# == Class role::statistics::explorer
# (stat1004)
# Access to analytics Hadoop cluster with private data.
# Not to be used for heavy local processing.
#
class role::statistics::explorer {
    system::role { 'statistics::explorer':
        description => 'Statistics & Analytics cluster explorer (private data access, no local compute)'
    }

    # TEMP for T211327
    # To be removed (with purge of packages) ASAP
    require_package('exfat-fuse', 'exfat-utils')

    include ::standard
    include ::profile::statistics::explorer
    include ::profile::analytics::cluster::client
    # This is a Hadoop client, and should
    # have any special analytics system users on it
    # for interacting with HDFS.
    include ::profile::analytics::cluster::users
    include ::profile::analytics::refinery
    include ::profile::analytics::cluster::packages::hadoop
}
