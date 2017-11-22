# == Class role::statistics::explorer
# (stat1004)
# Access to analytics Hadoop cluster with private data.
# Not to be used for heavy local processing.
#
class role::statistics::explorer {
    include ::profile::statistics::explorer
    include ::role::analytics_cluster::client
    include ::role::analytics_cluster::refinery
}
