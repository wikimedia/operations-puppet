# == Class role::analytics_cluster::hadoop::client
# Simple role class that only includes a hadoop client.
#
class role::analytics_test_cluster::client {
    system::role { 'analytics_test_cluster::client':
        description => 'Analytics Hadoop test client',
    }

    include ::profile::java
    include ::profile::base::production
    include ::profile::base::firewall
    include ::profile::analytics::cluster::client
    include ::profile::kerberos::client
    include ::profile::kerberos::keytabs

    include ::profile::analytics::cluster::gitconfig

    # Airflow job scheduler.
    # We run this here in the analytics-test cluster
    # because we don't have a 'launcher' role node there,
    # and we can't run hive clients on the same node
    # as the hive server, as we use dns_canonicalize_hostname=true there,
    # which causes Hive Kerberos authentication to fail from that host.
    # NOTE: we only want airflow on ONE client instance.
    # This conditional is a hack to ensure that if someone ever creates
    # a more an-test-client instances, that the airflow-analytics-test
    # instance is not created there accidentally.
    if $::fqdn == 'an-test-client1001.eqiad.wmnet' {
        include ::profile::airflow
    }

    include ::profile::presto::client

    # Need refinery to test Refine jobs
    include ::profile::analytics::refinery

    include ::profile::analytics::jupyterhub
}
