# == Class role::restbase
#

@monitoring::group { 'restbase_eqiad': description => 'Restbase eqiad' }
@monitoring::group { 'restbase_codfw': description => 'Restbase codfw' }

# Config should be pulled from hiera
class role::restbase {
    system::role { 'restbase': description => "Restbase ${::realm}" }

    include ::restbase

    include lvs::realserver


    ferm::service {'restbase_web':
        proto => 'tcp',
        port  => '7231',
    }

}

class role::restbase::alerts {
    monitoring::graphite_threshold { 'restbase_request_5xx_rate':
        description    => 'RESTBase req/s returning 5xx',
        metric         => 'transformNull(restbase.v1_page_html_-title-_-revision--_tid-.GET.5xx.sample_rate, 0)',
        from           => '10min',
        warning        => '1', # 1 5xx/s
        critical       => '3', # 5 5xx/s
        percentage     => '20',
        contact_group  => 'team-services',
    }

    monitoring::graphite_threshold { 'restbase_html_storage_hit_latency':
        description    => 'RESTBase HTML storage load mean latency ms',
        metric         => 'movingMedian(restbase.sys_key-rev-value_-bucket-_-key--_revision--_tid-.GET.2xx.mean, 15)',
        from           => '10min',
        warning        => '25', # 25ms
        critical       => '50', # 50ms
        percentage     => '50',
        contact_group  => 'team-services',
    }

    monitoring::graphite_threshold { 'restbase_html_storage_hit_latency_99p':
        description    => 'RESTBase HTML storage load 99p latency ms',
        metric         => 'movingMedian(restbase.sys_key-rev-value_-bucket-_-key--_revision--_tid-.GET.2xx.p99, 15)',
        from           => '10min',
        warning        => '25', # 25ms
        critical       => '50', # 50ms
        percentage     => '50',
        contact_group  => 'team-services',
    }

    monitoring::graphite_threshold { 'restbase_cassandra_highest_storage_exceptions':
        description    => 'RESTBase Cassandra highest storage exceptions (http://grafana.wikimedia.org/#/dashboard/db/restbase-cassandra-storage)',
        metric         => 'highestMax(movingAverage(nonNegativeDerivative(cassandra.*.org.apache.cassandra.metrics.Storage.Exceptions.count), 5), 1)',
        from           => '10min',
        warning        => '5',
        critical       => '10',
        percentage     => '50',
        contact_group  => 'team-services',
    }

    monitoring::graphite_threshold { 'restbase_cassandra_highest_total_hints':
        description    => 'RESTBase Cassandra highest total hints (http://grafana.wikimedia.org/#/dashboard/db/restbase-cassandra-storage)',
        metric         => 'highestMax(movingAverage(nonNegativeDerivative(cassandra.*.org.apache.cassandra.metrics.Storage.TotalHints.count), 5), 1)',
        from           => '10min',
        warning        => '600',
        critical       => '1000',
        percentage     => '50',
        contact_group  => 'team-services',
    }

    monitoring::graphite_threshold { 'restbase_cassandra_highest_pending_compactions':
        description    => 'RESTBase Cassandra highest pending compactions (http://grafana.wikimedia.org/#/dashboard/db/restbase-cassandra-compaction)',
        metric         => 'highestMax(cassandra.*.org.apache.cassandra.metrics.Compaction.PendingTasks.value, 1)',
        from           => '10min',
        warning        => '100',
        critical       => '400',
        percentage     => '50',
        contact_group  => 'team-services',
    }

    monitoring::graphite_threshold { 'restbase_cassandra_highest_sstables_per_read':
        description    => 'RESTBase Cassandra highest SSTables per-read (http://grafana.wikimedia.org/#/dashboard/db/restbase-cassandra-cf-sstables-per-read)',
        metric         => 'highestMax(movingAverage(cassandra.*.org.apache.cassandra.metrics.ColumnFamily.all.SSTablesPerReadHistogram.99percentile, 5), 1)',
        from           => '10min',
        warning        => '6',
        critical       => '10',
        percentage     => '50',
        contact_group  => 'team-services',
    }

        monitoring::graphite_threshold { 'restbase_cassandra_highest_tombstones_scanned':
        description    => 'RESTBase Cassandra highest tombstones scanned (http://grafana.wikimedia.org/#/dashboard/db/restbase-cassandra-cf-tombstones-scanned)',
        metric         => 'highestMax(movingAverage(cassandra.*.org.apache.cassandra.metrics.ColumnFamily.all.TombstoneScannedHistogram.99percentile, 5), 1)',
        from           => '10min',
        warning        => '1000',
        critical       => '1500',
        percentage     => '50',
        contact_group  => 'team-services',
    }
}
