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

    monitoring::graphite_threshold { 'restbase_cassandra_storage_exceptions':
        description    => 'RESTBase Cassandra storage exceptions',
        metric         => 'sumSeries(nonNegativeDerivative(cassandra.*.org.apache.cassandra.metrics.Storage.Exceptions.count))',
        from           => '10min',
        warning        => '5',
        critical       => '10',
        percentage     => '50',
        contact_group  => 'team-services',
    }

    monitoring::graphite_threshold { 'restbase_cassandra_storage_total_hints':
        description    => 'RESTBase Cassandra storage total hints',
        metric         => 'sumSeries(nonNegativeDerivative(cassandra.*.org.apache.cassandra.metrics.Storage.TotalHints.count))',
        from           => '10min',
        warning        => '1000',
        critical       => '2000',
        percentage     => '50',
        contact_group  => 'team-services',
    }
}
