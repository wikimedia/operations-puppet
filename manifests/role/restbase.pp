# == Class role::restbase
# Config should be pulled from hiera
class role::restbase {
    system::role { 'restbase': description => "Restbase ${::realm}" }

    include ::passwords::cassandra
    include base::firewall

    include ::restbase
    include ::restbase::monitoring

    include lvs::realserver

    # Add conftool scripts and credentials
    include ::conftool::scripts

    # RESTBase rate limiting DHT firewall rule
    $rb_hosts_ferm = join(hiera('restbase::hosts'), ' ')
    ferm::service { 'restbase-ratelimit':
        proto  => 'tcp',
        port   => '3050',
        srange => "@resolve((${rb_hosts_ferm}))",
    }

    ferm::service {'restbase_web':
        proto => 'tcp',
        port  => '7231',
    }

}

class role::restbase::alerts {
    monitoring::graphite_threshold { 'restbase_request_5xx_rate':
        description   => 'RESTBase html revision 5xx req/s https://grafana.wikimedia.org/dashboard/db/restbase',
        metric        => 'transformNull(restbase.external.v1_page_html_-title-_-revision--_tid-.GET.5xx.sample_rate, 0)',
        from          => '10min',
        warning       => '1', # 1 5xx/s
        critical      => '3', # 5 5xx/s
        percentage    => '20',
        contact_group => 'team-services',
    }

    monitoring::graphite_threshold { 'restbase_html_storage_hit_latency':
        description   => 'RESTBase HTML revision request mean storage latency ms https://grafana.wikimedia.org/dashboard/db/restbase',
        metric        => 'movingMedian(restbase.external.sys_key-rev-value_-bucket-_-key--_revision--_tid-.GET.2xx.mean, 15)',
        from          => '10min',
        warning       => '25', # 25ms
        critical      => '50', # 50ms
        percentage    => '50',
        contact_group => 'team-services',
    }

    monitoring::graphite_threshold { 'restbase_html_storage_hit_latency_99p':
        description   => 'RESTBase HTML revision request 99p storage latency ms https://grafana.wikimedia.org/dashboard/db/restbase',
        metric        => 'movingMedian(restbase.external.sys_key-rev-value_-bucket-_-key--_revision--_tid-.GET.2xx.p99, 15)',
        from          => '10min',
        warning       => '1500', # 1.5s
        critical      => '3000', # 3s
        percentage    => '50',
        contact_group => 'team-services',
    }

    monitoring::graphite_threshold { 'restbase_cassandra_highest_storage_exceptions':
        description   => 'RESTBase Cassandra highest storage exceptions http://grafana.wikimedia.org/#/dashboard/db/restbase-cassandra-storage',
        metric        => 'highestMax(nonNegativeDerivative(cassandra.restbase10*.org.apache.cassandra.metrics.Storage.Exceptions.count), 1)',
        from          => '10min',
        warning       => '5',
        critical      => '10',
        percentage    => '50',
        contact_group => 'team-services',
    }

    monitoring::graphite_threshold { 'restbase_cassandra_highest_total_hints':
        description   => 'RESTBase Cassandra highest total hints http://grafana.wikimedia.org/#/dashboard/db/restbase-cassandra-storage',
        metric        => 'highestMax(nonNegativeDerivative(cassandra.restbase10*.org.apache.cassandra.metrics.Storage.TotalHints.count), 1)',
        from          => '10min',
        warning       => '600',
        critical      => '1000',
        percentage    => '50',
        contact_group => 'team-services',
    }

    monitoring::graphite_threshold { 'restbase_cassandra_highest_pending_compactions':
        description   => 'RESTBase Cassandra highest pending compactions http://grafana.wikimedia.org/#/dashboard/db/restbase-cassandra-compaction',
        metric        => 'highestMax(cassandra.restbase10*.org.apache.cassandra.metrics.Compaction.PendingTasks.value, 1)',
        from          => '60min',
        warning       => '4000',
        critical      => '5000',
        percentage    => '50',
        contact_group => 'team-services',
    }

    # With instance sizes in-flux, and expansions taking place, it is proving
    # difficult to provide meaningful thresholds that are entirely immune from
    # false positives.  Hopefully we can re-enable this in the near future,
    # when things have settled a bit, or when an alternative form of alerting
    # can be found.
    # monitoring::graphite_threshold { 'restbase_cassandra_highest_sstables_per_read':
    #     description   => 'RESTBase Cassandra highest SSTables per-read http://grafana.wikimedia.org/#/dashboard/db/restbase-cassandra-cf-sstables-per-read',
    #     metric        => 'highestMax(cassandra.restbase10*.org.apache.cassandra.metrics.ColumnFamily.all.SSTablesPerReadHistogram.99percentile, 1)',
    #     from          => '10min',
    #     warning       => '35',
    #     critical      => '50',
    #     percentage    => '50',
    #     contact_group => 'team-services',
    # }

    monitoring::graphite_threshold { 'restbase_cassandra_highest_tombstones_scanned':
        description   => 'RESTBase Cassandra highest tombstones scanned http://grafana.wikimedia.org/#/dashboard/db/restbase-cassandra-cf-tombstones-scanned',
        metric        => 'highestMax(cassandra.restbase10*.org.apache.cassandra.metrics.ColumnFamily.all.TombstoneScannedHistogram.99percentile, 1)',
        from          => '10min',
        warning       => '1000',
        critical      => '1500',
        percentage    => '50',
        contact_group => 'team-services',
    }

    monitoring::graphite_threshold { 'restbase_cassandra_highest_pending_internal':
        description   => 'RESTBase Cassandra highest pending internal thread pool tasks http://grafana.wikimedia.org/#/dashboard/db/restbase-cassandra-thread-pools',
        metric        => 'highestMax(exclude(cassandra.restbase10*.org.apache.cassandra.metrics.ThreadPools.internal.*.PendingTasks.value, "CompactionExecutor"), 1)',
        from          => '10min',
        warning       => '500',
        critical      => '1000',
        percentage    => '50',
        contact_group => 'team-services',
    }

    monitoring::graphite_threshold { 'restbase_cassandra_highest_dropped_messages':
        description   => 'RESTBase Cassandra highest dropped message rate http://grafana.wikimedia.org/#/dashboard/db/restbase-cassandra-dropped-messages',
        metric        => 'highestMax(cassandra.restbase10*.org.apache.cassandra.metrics.DroppedMessage.*.Dropped.1MinuteRate, 1)',
        from          => '10min',
        warning       => '50',
        critical      => '100',
        percentage    => '50',
        contact_group => 'team-services',
    }
}
