# Class: role::cloud_analytics::master
#
# Hadoop master in the cloud-analytics cluster.
#
class role::cloud_analytics::master {
    system::role { 'cloud_analytics::master':
        description => 'cloud-analytics Hadoop Master',
    }

    include ::profile::hadoop::master
}
