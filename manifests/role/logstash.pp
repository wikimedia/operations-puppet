@monitor_group { 'logstash_eqiad': description => 'eqiad logstash' }

# == Class: role::logstash
#
# Provisions LogStash and ElasticSearch.
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

    class { '::logstash':
       heap_memory    => '128m',
       filter_workers => '3',
    }

    class { '::logstash::input::udp2log':
        port => '8324'
    }
    class { '::logstash::input::syslog':
        port => '514',
    }
    class { '::logstash::input::redis':
        host => '127.0.0.1',
        key  => 'logstash',
    }

    @logstash::conf { 'color-filter':
        content => 'filter { mutate { gsub => [ "message", "\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]", "" ] } }'
    }

}
# vim:sw=4 ts=4 sts=4 et:
