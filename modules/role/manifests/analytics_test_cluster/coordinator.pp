# == Class role::analytics_test_cluster::coordinator
#
# This role includes the Hive and Presto servers, as well as an analytics_meta
# MariadDB instance.
#
#
class role::analytics_test_cluster::coordinator {
    include profile::analytics::cluster::gitconfig

    include profile::java
    include profile::analytics::cluster::client
    include profile::analytics::database::meta

    # SQL-like queries to data stored in HDFS
    include profile::hive::metastore
    include profile::hive::server

    # (Faster) SQL-like queries to data stored in HDFS and elsewhere
    # coordinator only runs the Presto server as a coordinator process.
    # The actual workers are configured in the presto::server role.
    # This node is marked as a coordinator in hiera.
    include profile::presto::server

    # Include a weekly cron job to run hdfs balancer.
    include profile::hadoop::balancer

    # kafkatee + kafkacat set up to read only a small
    # subset of webrequest traffic and send it to a testing
    # topic.
    include profile::kafkatee::webrequest::analytics

    # Various crons that launch Hadoop jobs.
    include profile::analytics::refinery
    include profile::analytics::refinery_git_config

    # Gobblin imports data from Kafka into HDFS.
    include profile::analytics::refinery::job::test::gobblin
    include profile::analytics::refinery::job::test::refine
    include profile::analytics::refinery::job::test::refine_sanitize
    include profile::analytics::refinery::job::test::data_purge

    include profile::kerberos::keytabs

    include profile::base::production
    include profile::firewall

    include profile::kerberos::client

    # Temporary rule to test JupyterHub + YarnSpawner.
    # Notebook Serviers running in Yarn Hadoop Workers=
    # need to be able to contact JupyterHub.
    # Bug: T224658
    ferm::service{ 'jupyterhub_hub':
        proto  => 'tcp',
        port   => '8081',
        srange => '$ANALYTICS_NETWORKS',
    }
}
