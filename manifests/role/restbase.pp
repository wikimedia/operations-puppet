# == Class role::restbase
# Config should be pulled from hiera
class role::restbase {
    system::role { 'restbase': description => "Restbase ${::realm}" }

    include ::passwords::cassandra
    include base::firewall

    include ::restbase
    include ::restbase::monitoring

    # Add a script to make deployment easier
    service::deployment_script { 'restbase':
        monitor_url => $::restbase::monitoring::monitor_url,
    }

    include lvs::realserver


    ferm::service {'restbase_web':
        proto => 'tcp',
        port  => '7231',
    }

}

class role::restbase::alerts {
    monitoring::graphite_threshold { 'restbase_request_5xx_rate':
        description   => 'RESTBase req/s returning 5xx http://grafana.wikimedia.org/#/dashboard/db/restbase',
        metric        => 'transformNull(restbase.v1_page_html_-title-_-revision--_tid-.GET.5xx.sample_rate, 0)',
        from          => '10min',
        warning       => '1', # 1 5xx/s
        critical      => '3', # 5 5xx/s
        percentage    => '20',
        contact_group => 'team-services',
    }

    monitoring::graphite_threshold { 'restbase_html_storage_hit_latency':
        description   => 'RESTBase HTML storage load mean latency ms http://grafana.wikimedia.org/#/dashboard/db/restbase',
        metric        => 'movingMedian(restbase.sys_key-rev-value_-bucket-_-key--_revision--_tid-.GET.2xx.mean, 15)',
        from          => '10min',
        warning       => '25', # 25ms
        critical      => '50', # 50ms
        percentage    => '50',
        contact_group => 'team-services',
    }

    monitoring::graphite_threshold { 'restbase_html_storage_hit_latency_99p':
        description   => 'RESTBase HTML storage load 99p latency ms http://grafana.wikimedia.org/#/dashboard/db/restbase',
        metric        => 'movingMedian(restbase.sys_key-rev-value_-bucket-_-key--_revision--_tid-.GET.2xx.p99, 15)',
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

    monitoring::graphite_threshold { 'restbase_cassandra_highest_sstables_per_read':
        description   => 'RESTBase Cassandra highest SSTables per-read http://grafana.wikimedia.org/#/dashboard/db/restbase-cassandra-cf-sstables-per-read',
        metric        => 'highestMax(cassandra.restbase10*.org.apache.cassandra.metrics.ColumnFamily.all.SSTablesPerReadHistogram.99percentile, 1)',
        from          => '10min',
        warning       => '15',
        critical      => '30',
        percentage    => '50',
        contact_group => 'team-services',
    }

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
