# == Class role::analytics_cluster::hadoop::worker
#
# filtertags: labs-project-analytics labs-project-math
class role::analytics_cluster::hadoop::worker {
    system::role { 'analytics_cluster::hadoop::worker':
        description => 'Hadoop Worker (DataNode & NodeManager)',
    }

    include ::profile::hadoop::client
    include ::profile::hadoop::worker

    # hive::client is nice to have for jobs launched
    # from random worker nodes as app masters so they
    # have access to hive-site.xml and other hive jars.
    # This installs hive-hcatalog package on worker nodes to get
    # hcatalog jars, including Hive JsonSerde for using
    # JSON backed Hive tables.
    include ::profile::hive::client
}
