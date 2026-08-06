# == Class role::analytics_test_cluster::hadoop::client
# Simple role class that only includes a hadoop client.
#
class role::analytics_test_cluster::client {
    include profile::java
    include profile::base::production
    include profile::firewall
    include profile::analytics::cluster::client
    include profile::kerberos::client
    include profile::kerberos::keytabs

    include profile::analytics::cluster::gitconfig

    include profile::presto::client

    # Need refinery to test Refine jobs
    include profile::analytics::refinery

    include profile::analytics::jupyterhub
}
