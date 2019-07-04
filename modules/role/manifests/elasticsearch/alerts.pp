class role::elasticsearch::alerts {
    monitoring::graphite_threshold { 'cirrussearch_eqiad_95th_percentile':
        description     => 'CirrusSearch eqiad 95th percentile latency',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/elasticsearch-percentiles?panelId=19&fullscreen&orgId=1&var-cluster=eqiad&var-smoothing=1'],
        metric          => 'transformNull(MediaWiki.CirrusSearch.eqiad.requestTime.p95, 0)',
        from            => '10min',
        warning         => 500,
        critical        => 1000,
        percentage      => 20,
        contact_group   => 'team-discovery',
    }

    monitoring::graphite_threshold { 'cirrussearch_codfw_95th_percentile':
        description     => 'CirrusSearch codfw 95th percentile latency - more_like',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/elasticsearch-percentiles?panelId=39&fullscreen&orgId=1&var-cluster=codfw&var-smoothing=1'],
        metric          => 'transformNull(MediaWiki.CirrusSearch.codfw.requestTimeMs.more_like.p95, 0)',
        from            => '10min',
        warning         => 1200,
        critical        => 2000,
        percentage      => 20,
        contact_group   => 'team-discovery',
    }

    # warning level is ~1% of peak traffic failing
    monitoring::graphite_threshold { 'search_backend_failure_count':
        description     => 'Number of backend failures per minute from CirrusSearch',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/elasticsearch-percentiles?orgId=1&var-cluster=eqiad&var-smoothing=1&panelId=9&fullscreen'],
        metric          => 'transformNull(MediaWiki.CirrusSearch.eqiad.backend_failure.failed.count, 0)',
        from            => '10min',
        warning         => 300,
        critical        => 600,
        percentage      => 20,
        contact_group   => 'team-discovery',
    }
}
