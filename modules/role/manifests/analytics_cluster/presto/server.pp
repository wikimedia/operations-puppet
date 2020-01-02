# Class: role::analytics_cluster::presto::server
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
class role::analytics_cluster::presto::server {
    system::role { 'analytics_cluster::presto::server':
        description => 'Presto server',
    }

    include ::profile::standard
    include ::profile::base::firewall

    include ::profile::hadoop::common
    include ::profile::presto::server

    include ::profile::kerberos::client
    include ::profile::kerberos::keytabs
}
