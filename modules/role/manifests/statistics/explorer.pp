# == Class role::statistics::explorer
# (stat1004)
# Access to analytics Hadoop cluster with private data.
# Not to be used for heavy local processing.
#
class role::statistics::explorer {
    system::role { 'statistics::explorer':
        description => 'Statistics & Analytics cluster explorer (private data access, no local compute)'
    }

    include ::profile::statistics::explorer
    include ::role::analytics_cluster::client
    include ::role::analytics_cluster::refinery
}
