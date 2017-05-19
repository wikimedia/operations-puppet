# == Class role::zookeeper::server
#
# filtertags: labs-project-deployment-prep labs-project-analytics
class role::zookeeper::server {
    include profile::zookeeper::client
    include profile::zookeeper::server
}
