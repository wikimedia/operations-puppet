# Class: role::cloud_analytics::worker
#
# Hadoop and Presto worker in the cloud-analytics cluster.
#
class role::cloud_analytics::worker {
    system::role { 'cloud_analytics::worker':
        description => 'cloud-analytics Hadoop and Presto Worker',
    }

    include ::profile::hadoop::worker
}
