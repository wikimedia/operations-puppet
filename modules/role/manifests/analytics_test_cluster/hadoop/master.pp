# == Class role::analytics_test_cluster::hadoop::master
# Includes bigtop::hadoop::master classes
#
class role::analytics_test_cluster::hadoop::master {
    include profile::java
    include profile::hadoop::master
    # This is a Hadoop client, and should
    # have any service system users it needs to
    # interacting with HDFS.
    include profile::analytics::cluster::users
    include profile::hadoop::firewall::master

    # This needs to be included only on single Hadoop node.
    include profile::analytics::cluster::secrets

    include profile::analytics::cluster::hadoop::yarn_capacity_scheduler

  # Include some test secrets
    include profile::analytics::cluster::secrets_test

    # Set up druid cluster deep storage directories.
    include profile::analytics::cluster::druid_deep_storage

    include profile::kerberos::client
    include profile::kerberos::keytabs

    include profile::firewall
    include profile::base::production
}
