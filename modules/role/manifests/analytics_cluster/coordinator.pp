# == Class role::analytics_cluster::coordinator
#
# This role includes Oozie and Hive servers, as well as a MySQL instance
# that stores meta data associated with those and other
# Analytics Cluster services.
#
# This roles sets up a node responsible to coordinate and orchestrate
# a Hadoop cluster equipped with tools like Camus, Hive, Oozie, Presto, etc..
#
class role::analytics_cluster::coordinator {

    system::role { 'analytics_cluster::coordinator':
        description => 'Analytics Cluster host running various Hadoop services (Hive, Presto, Oozie, ..)'
    }

    include ::profile::analytics::cluster::gitconfig

    include ::profile::java

    include ::profile::analytics::cluster::client
    include ::profile::analytics::database::meta

    # SQL-like queries to data stored in HDFS
    include ::profile::hive::metastore
    include ::profile::hive::server

    # (Faster) SQL-like queries to data stored in HDFS and elsewhere
    # coordinator only runs the Presto server as a coordinator process.
    # The actual workers are configured in the presto::server role.
    # This node is marked as a coordinator in hiera.
    include ::profile::presto::server

    # The Hadoop job scheduler
    include ::profile::oozie::server

    include ::profile::analytics::refinery
    include ::profile::analytics::cluster::repositories::statistics

    include ::profile::kerberos::client
    include ::profile::kerberos::keytabs

    include ::profile::standard
    include ::profile::base::firewall
}
