# Class: role::cloud_analytics::conf
#
# Zookeeper server in the cloud-analytics cluster./
class role::cloud_analytics::config {
    include profile::zookeeper::server
}
