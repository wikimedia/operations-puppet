# == Class role::analytics_cluster::oozie::client
#
class role::analytics_cluster::oozie::client {
    include ::role::analytics_cluster::hadoop::client

    class { '::cdh::oozie': }
}