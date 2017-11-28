# == Class profile::oozie::client
#
# filtertags: labs-project-math labs-project-analytics
class profile::oozie::client {
    class { '::cdh::oozie': }
}