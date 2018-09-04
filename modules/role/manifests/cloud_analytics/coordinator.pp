# Class: role::cloud_analytics::coordinator
#
# Hive server and metastore in the cloud-analytics cluster.
#
class role::cloud_analytics::coordinator {
    system::role { 'cloud_analytics::coordinator':
        description => 'cloud-analytics host hosting Hadoop services (Hive, etc.) and maintenance scripts'
    }

    # TODO: backup to ca-master1002
    # Back up analytics-meta MySQL instance
    # to an-master1002.
    # include ::profile::analytics::database::meta::backup

    include ::profile::hive::metastore
    include ::profile::hive::server
    include ::profile::hive::metastore::database

    # Include a weekly cron job to run hdfs balancer.
    include ::profile::hadoop::balancer

    include ::profile::presto::client
}
