 # role/analytics/hadoop.pp
#
# Role classes for Analytics Hadoop nodes.
# These role classes will configure Hadoop properly in either
# the Labs or Production environments.
#
#
# Production configs are hardcoded here.  Labs has a few parameters
# that need to be specified as global variables via the Manage Instances GUI:
#
# $cluster_name       - Logical name of this cluster.  Required.
#
# $hadoop_namenodes   - Comma separated list of FQDNs that should be NameNodes
#                       for this cluster.  The first entry in the list
#                       is assumed to be the preferred primary NameNode.  Required.
#                       This list will also be used as $resourcemanager_hosts.
#                       If hiera('zookeeper_hosts') is set, and this list has more
#                       than one entry, and $journalnode_hosts is also set, then
#                       HA YARN ResourceManager will be configured.
#                       TODO: Change the name of this variable to hadoop_masters
#                       When we make this work better with hiera.
#
# $journalnode_hosts  - Comma separated list of FQDNs that should be JournalNodes
#                       for this cluster.  Optional.  If not specified, HA will not be configured.
#
# $heapsize           - Optional.  Set this to a value in MB to limit the JVM
#                       heapsize for all Hadoop daemons.  Optional.
#
#
# Usage:
#
# To install only hadoop client packages and configs:
#   include role::analytics::hadoop::client
#
# To install a Hadoop Master (NameNode + ResourceManager, etc.):
#   include role::analytics::hadoop::master
#
# To install a Hadoop Worker (DataNode + NodeManager + etc.):
#   include role::analytics::hadoop::worker
#
