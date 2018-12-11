# Class: role::cloud_analytics::conf
#
# Zookeeper server in the cloud-analytics cluster./
class role::cloud_analytics::config {
    system::role { 'cloud_analytics::config':
        description => 'cloud-analytics \'configcluster\' services (currently only Zookeeper)',
    }

    include ::profile::zookeeper::server
}
