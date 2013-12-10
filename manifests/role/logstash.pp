@monitor_group { 'logstash_eqiad': description => 'eqiad logstash' }

# == Class: role::logstash
#
# Provisions LogStash, Redis, and ElasticSearch.
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

    include ::passwords::logstash

    class { "::redis":
        maxmemory         => '5Gb',
        persist           => undef,
        redis_replication => undef,
        password          => $passwords::logstash::redis,
    }

    include ::redis::ganglia
}
