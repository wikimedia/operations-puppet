# Class: role::cloud_analytics::standby
#
# Hadoop standby master in the cloud-analytics cluster.
#
class role::cloud_analytics::standby {
    system::role { 'cloud_analytics::standby':
        description => 'cloud-analytics Hadoop Master Standby',
    }

    include ::profile::hadoop::master::standby
}
