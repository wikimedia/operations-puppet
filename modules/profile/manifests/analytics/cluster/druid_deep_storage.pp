# Class: profile::analytics::cluster::druid_deep_storage
#
# This file ensures that druid users and groups exist, and that
# HDFS directories are created for Analytics Cluster druid clusters
# so they can be backed by HDFS for deep storage of datasets.
#
# This should be included on only one node that should also
# have druid users...a single Hadoop master is a good place.
#
class profile::analytics::cluster::druid_deep_storage {
    # Ensure that druid deep storage directories exist for all Druid clusters.
    ::druid::cdh::hadoop::deep_storage { 'analytics-eqiad':
        # analytics-eqiad predates the time when there were multiple Druid clusters.
        # It's deep storage directory will be /user/druid/deep-storage.
        path => '/user/druid/deep-storage',
    }
    # The Druid public-eqiad cluster's deep storage
    # directory will be /user/druid/deep-storage-public-eqiad
    ::druid::cdh::hadoop::deep_storage { 'public-eqiad': }
}
