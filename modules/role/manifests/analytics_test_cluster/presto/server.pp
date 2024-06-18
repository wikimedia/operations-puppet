# Class: role::analytics_test_cluster::presto::server
#
# Sets up a presto server in the analytics cluster using Analytics Hadoop and Hive.
#
# NOTE: This role is used both by the presto coordinator / discovery node
# as well as the worker nodes.  Configuration of which is done via
# hiera in profile::presto::server::config_properties by setting
# profile::presto::server::config_properties:
#   "coordinator": true
#   "node-scheduler.include-coordinator": false
#   "discovery-server.enabled": true
#   #
class role::analytics_test_cluster::presto::server {
    include profile::base::production
    include profile::firewall

    include profile::java
    include profile::hadoop::common
    include profile::presto::server

    include profile::kerberos::client
    include profile::kerberos::keytabs
}
