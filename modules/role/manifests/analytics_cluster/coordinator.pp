# == Class role::analytics_cluster::coordinator
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
class role::analytics_cluster::coordinator {

    system::role { 'analytics_cluster::coordinator':
        description => 'Analytics Cluster host running various Hadoop services (Hive, Camus, Oozie, ..) and maintenance scripts'
    }

    include ::role::analytics_cluster::client
    include ::profile::analytics::database::meta

    # Back up analytics-meta MySQL instance
    # to analytics1002.
    include ::profile::analytics::database::meta::backup

    # SQL-like queries to data stored in HDFS
    include ::profile::hive::metastore
    include ::profile::hive::server
    include ::profile::hive::metastore::database

    # The Hadoop job scheduler
    include ::profile::oozie::server
    include ::profile::oozie::server::database

    # Camus crons import data into
    # from Kafka into HDFS.
    include ::role::analytics_cluster::refinery::job::camus

    # Include a weekly cron job to run hdfs balancer.
    include ::role::analytics_cluster::hadoop::balancer

    # We need hive-site.xml in HDFS.  This can be included
    # on any node with a Hive client, but we really only
    # want to include it in one place.  analytics1003
    # is a little special and standalone, so we do it here.
    include ::role::analytics_cluster::hive::site_hdfs

    # Various crons that launch Hadoop jobs.
    include ::role::analytics_cluster::refinery
    include ::role::analytics_cluster::refinery::job::data_drop
    include ::role::analytics_cluster::refinery::job::project_namespace_map
    include ::role::analytics_cluster::refinery::job::sqoop_mediawiki
    include ::role::analytics_cluster::refinery::job::json_refine

    class { '::standard': }
    include ::profile::base::firewall
}