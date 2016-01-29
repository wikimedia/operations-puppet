# == Class role::analytics::oozie::client
#
class role::analytics_new::oozie::client {
    include role::analytics_new::hadoop::client

    class { 'cdh::oozie': }
}