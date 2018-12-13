# Class: role::cloud_analytics::standby
#
# Hadoop standby master in the cloud-analytics cluster.
#
class role::cloud_analytics::standby {
    system::role { 'cloud_analytics::standby':
        description => 'cloud-analytics Hadoop Master Standby',
    }

    include ::profile::hadoop::master::standby
    # Run a presto coordinator (not worker) here.
    # Coordinator vs worker is configured via hiera.
    include ::profile::presto::server
}
