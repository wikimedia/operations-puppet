# == Class role::analytics_test_cluster::coordinator
#
# This role includes Oozie and Hive servers, as well as a MySQL instance
# that stores meta data associated with those and other
# Analytics Cluster services.
#
# This role is a launch pad for various cron based Hadoop jobs.
# Many ingestion jobs need a starting point.  Oozie is a great
# Hadoop job scheduler, but it is not better than cron
# for some jobs that need to be launched at regular time
# intervals.  Cron is used for those.  These crons
# do not use local resources, instead, they launch
# Hadoop jobs that run throughout the cluster.
#
# This roles sets up a node responsible to coordinate and orchestrate
# a Hadoop cluster equipped with tools like Camus, Hive, Oozie and
# the Analytics Refinery.
#
class role::analytics_test_cluster::coordinator {

    system::role { 'analytics_test_cluster::coordinator':
        description => 'Analytics Cluster host running various Hadoop services (Hive, Camus, Oozie, ..) and maintenance scripts'
    }

    include ::profile::analytics::cluster::gitconfig

    include ::profile::analytics::cluster::client
    include ::profile::analytics::database::meta

    # This is a Hadoop client, and should
    # have any special analytics system users on it
    # for interacting with HDFS.
    include ::profile::hadoop::users

    # Back up analytics-meta MySQL instance
    # to an-master1002.
    include ::profile::analytics::database::meta::backup

    # SQL-like queries to data stored in HDFS
    include ::profile::hive::metastore
    include ::profile::hive::server
    include ::profile::hive::metastore::database

    # The Hadoop job scheduler
    include ::profile::oozie::server
    include ::profile::oozie::server::database

    # Include a weekly cron job to run hdfs balancer.
    include ::profile::hadoop::balancer

    # kafkatee + kafkacat set up to read only a small
    # subset of webrequest traffic and send it to a testing
    # topic. 
    include ::profile::kafkatee::webrequest::analytics

    # Various crons that launch Hadoop jobs.
    include ::profile::analytics::refinery

    # Camus crons import data into
    # from Kafka into HDFS.
    include ::profile::analytics::refinery::job::test::camus
    #include ::profile::analytics::refinery::job::test::data_purge
    #include ::profile::analytics::refinery::job::refine

    include ::profile::standard
    include ::profile::base::firewall

    include ::profile::kerberos::client
}
