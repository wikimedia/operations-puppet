# == Class role::analytics_cluster::hadoop::worker
#
# filtertags: labs-project-analytics labs-project-math
class role::analytics_cluster::hadoop::worker {
    system::role { 'analytics_cluster::hadoop::worker':
        description => 'Hadoop Worker (DataNode & NodeManager)',
    }
    include ::profile::hadoop::worker
    include ::profile::hadoop::logstash
    include ::profile::base::firewall
    include standard
}
