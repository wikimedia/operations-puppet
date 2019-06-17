# == Class role::analytics_test_cluster::hadoop::worker
#
# filtertags: labs-project-analytics labs-project-math
class role::analytics_test_cluster::hadoop::worker {
    system::role { 'analytics_test_cluster::hadoop::worker':
        description => 'Hadoop Worker (DataNode & NodeManager)',
    }
    include ::profile::hadoop::worker
    include ::profile::analytics::cluster::users
    include ::profile::kerberos::client
    include ::profile::base::firewall
    include ::profile::standard
}
