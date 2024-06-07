# Class: role::cloud_analytics::worker
#
# Hadoop and Presto worker in the cloud-analytics cluster.
#
class role::cloud_analytics::worker {
    include profile::hadoop::worker
    include profile::presto::server
}
