# == Class role::analytics_cluster::oozie::client
#
# filtertags: labs-project-math labs-project-analytics
class role::analytics_cluster::oozie::client {
    include ::role::analytics_cluster::hadoop::client

    class { '::cdh::oozie': }
}
