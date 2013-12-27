# vim:sw=4 ts=4 sts=4 et:
@monitor_group { 'logstash_eqiad': description => 'eqiad logstash' }

# == Class: role::logstash
#
# Provisions LogStash, Redis, and ElasticSearch.
#
class role::logstash {
    include ::elasticsearch::ganglia
    include ::elasticsearch::nagios::check
    include ::passwords::logstash
    include ::redis::ganglia

    deployment::target { 'elasticsearchplugins': }

    class { '::elasticsearch':
        multicast_group      => '224.2.2.5',
        master_eligible      => true,
        minimum_master_nodes => 2,
        cluster_name         => "production-logstash-${::site}",
        heap_memory          => '5G',
        plugins_dir          => '/srv/deployment/elasticsearch/plugins',
    }

    class { '::redis':
        maxmemory         => '1Gb',
        dir               => '/var/run/redis',
        persist           => undef,
        redis_replication => undef,
        password          => $passwords::logstash::redis,
    }


    class { '::logstash':
       heap_memory_mb => 128,
       filter_workers => 3,
    }

    class { '::logstash::input::udp2log':
        port => 8324,
    }
    class { '::logstash::input::syslog':
        port => 514,
    }
    class { '::logstash::input::redis':
        host => '127.0.0.1',
        key  => 'logstash',
    }

    @logstash::conf { 'filter-strip-ansi-color':
        source   => 'puppet:///files/logstash/filter-strip-ansi-color.conf',
        priority => 50,
    }

    @logstash::conf { 'filter-syslog':
        source   => 'puppet:///files/logstash/filter-syslog.conf',
        priority => 50,
    }

    class { '::logstash::output::elasticsearch':
        host            => '127.0.0.1',
        replication     => 'async',
        require_tag     => 'es',
        manage_indices  => 'true',
        priority        => 90,
    }

}
