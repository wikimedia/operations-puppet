# = Class: role::logstash
#
# This class sets up LogStash+Elasticsearch configuration in a WMF-specific way
#
class role::logstash {
    include ::elasticsearch::ganglia
    include ::elasticsearch::nagios::check

    deployment::target { 'elasticsearchplugins': }

    class { '::elasticsearch':
        multicast_group      => '224.2.2.5',
        master_eligible      => true,
        minimum_master_nodes => 2,
        cluster_name         => "production-logstash-${::site}",
        heap_memory          => '5G',
        plugins_dir          => '/srv/deployment/elasticsearch/plugins',
    }
}
