class role::restbase::alerts {
    monitoring::graphite_threshold { 'restbase_request_5xx_rate':
        description     => 'RESTBase html revision 5xx req/s',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/restbase?panelId=18&fullscreen&orgId=1&var-cluster=restbase'],
        metric          => 'transformNull(restbase.external.v1_page_html_-title-_-revision--_tid-.GET.5xx.sample_rate, 0)',
        from            => '10min',
        warning         => 1, # 1 5xx/s
        critical        => 3, # 5 5xx/s
        percentage      => 20,
        contact_group   => 'team-services',
        notes_link      => 'https://wikitech.wikimedia.org/wiki/RESTBase#Debugging',
    }

    monitoring::graphite_threshold { 'restbase_html_storage_hit_latency':
        description     => 'RESTBase HTML revision request mean storage latency ms',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/restbase?panelId=11&fullscreen&orgId=1&var-cluster=restbase'],
        metric          => 'movingMedian(restbase.external.sys_key-rev-value_-bucket-_-key--_revision--_tid-.GET.2xx.mean, 15)',
        from            => '10min',
        warning         => 25, # 25ms
        critical        => 50, # 50ms
        percentage      => 50,
        contact_group   => 'team-services',
        notes_link      => 'https://wikitech.wikimedia.org/wiki/RESTBase#Debugging',
    }

    monitoring::graphite_threshold { 'restbase_html_storage_hit_latency_99p':
        description     => 'RESTBase HTML revision request 99p storage latency ms',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/restbase?panelId=11&fullscreen&orgId=1&var-cluster=restbase'],
        metric          => 'movingMedian(restbase.external.sys_key-rev-value_-bucket-_-key--_revision--_tid-.GET.2xx.p99, 15)',
        from            => '10min',
        warning         => 1500, # 1.5s
        critical        => 3000, # 3s
        percentage      => 50,
        contact_group   => 'team-services',
        notes_link      => 'https://wikitech.wikimedia.org/wiki/RESTBase#Debugging',
    }

    monitoring::graphite_threshold { 'restbase_cassandra_highest_storage_exceptions':
        description     => 'RESTBase Cassandra highest storage exceptions',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/restbase-cassandra-storage?panelId=5&fullscreen&orgId=1&var-datacenter=1&var-node=All&var-keyspace=all'],
        metric          => 'highestMax(nonNegativeDerivative(cassandra.restbase10*.org.apache.cassandra.metrics.Storage.Exceptions.count), 1)',
        from            => '10min',
        warning         => 5,
        critical        => 10,
        percentage      => 50,
        contact_group   => 'team-services',
        notes_link      => 'https://wikitech.wikimedia.org/wiki/RESTBase#Debugging',
    }

    monitoring::graphite_threshold { 'restbase_cassandra_highest_total_hints':
        description     => 'RESTBase Cassandra highest total hints',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/restbase-cassandra-storage?panelId=28&fullscreen&orgId=1&var-datacenter=1&var-node=All&var-keyspace=all'],
        metric          => 'highestMax(nonNegativeDerivative(cassandra.restbase10*.org.apache.cassandra.metrics.Storage.TotalHints.count), 1)',
        from            => '10min',
        warning         => 600,
        critical        => 1000,
        percentage      => 50,
        contact_group   => 'team-services',
        notes_link      => 'https://wikitech.wikimedia.org/wiki/RESTBase#Debugging',
    }

    monitoring::graphite_threshold { 'restbase_cassandra_highest_pending_compactions':
        description     => 'RESTBase Cassandra highest pending compactions',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/restbase-cassandra-compaction?orgId=1&panelId=5&fullscreen&var-datacenter=1&var-node=All'],
        metric          => 'highestMax(cassandra.restbase10*.org.apache.cassandra.metrics.Compaction.PendingTasks.value, 1)',
        from            => '60min',
        warning         => 4000,
        critical        => 5000,
        percentage      => 50,
        contact_group   => 'team-services',
        notes_link      => 'https://wikitech.wikimedia.org/wiki/RESTBase#Debugging',
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
    #     warning       => 35,
    #     critical      => 50,
    #     percentage    => 50,
    #     contact_group => 'team-services',
    # }

    monitoring::graphite_threshold { 'restbase_cassandra_highest_tombstones_scanned':
        description     => 'RESTBase Cassandra highest tombstones scanned',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/restbase-cassandra-cf-tombstones-scanned?panelId=5&fullscreen&orgId=1&var-datacenter=1&var-node=All&var-quantiles=99percentile'],
        metric          => 'highestMax(cassandra.restbase10*.org.apache.cassandra.metrics.ColumnFamily.all.TombstoneScannedHistogram.99percentile, 1)',
        from            => '10min',
        warning         => 1000,
        critical        => 1500,
        percentage      => 50,
        contact_group   => 'team-services',
        notes_link      => 'https://wikitech.wikimedia.org/wiki/RESTBase#Debugging',
    }

    monitoring::graphite_threshold { 'restbase_cassandra_highest_pending_internal':
        description     => 'RESTBase Cassandra highest pending internal thread pool tasks',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/restbase-cassandra-thread-pools?panelId=34&fullscreen&orgId=1&var-datacenter=1&var-node=All'],
        metric          => 'highestMax(exclude(cassandra.restbase10*.org.apache.cassandra.metrics.ThreadPools.internal.*.PendingTasks.value, "CompactionExecutor"), 1)',
        from            => '10min',
        warning         => 500,
        critical        => 1000,
        percentage      => 50,
        contact_group   => 'team-services',
        notes_link      => 'https://wikitech.wikimedia.org/wiki/RESTBase#Debugging',
    }

    monitoring::graphite_threshold { 'restbase_cassandra_highest_dropped_messages':
        description     => 'RESTBase Cassandra highest dropped message rate',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/restbase-cassandra-dropped-messages?panelId=35&fullscreen&orgId=1&var-datacenter=1'],
        metric          => 'highestMax(cassandra.restbase10*.org.apache.cassandra.metrics.DroppedMessage.*.Dropped.1MinuteRate, 1)',
        from            => '10min',
        warning         => 50,
        critical        => 100,
        percentage      => 50,
        contact_group   => 'team-services',
        notes_link      => 'https://wikitech.wikimedia.org/wiki/RESTBase#Debugging',
    }
}
