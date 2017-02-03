# == Class role::analytics_cluster::druid::hadoop
# Ensures that the druid user exists and that
# druid directories exist in HDFS.  This should
# only be included on Hadoop NameNodes.
#
# filtertags: labs-project-analytics
class role::analytics_cluster::druid::hadoop {
    include ::druid::cdh::hadoop::setup
}
