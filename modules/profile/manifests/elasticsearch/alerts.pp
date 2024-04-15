class profile::elasticsearch::alerts {
    # For the following 6 alerts, they all follow the pattern of "only alert if qps volume is not negligible"
    # See https://phabricator.wikimedia.org/T347341#9197646 to understand specifcially how fallbackSeries/useSeriesAbove/constantLine achieve the above
    monitoring::graphite_threshold { 'cirrussearch_eqiad_fulltext_95th_percentile':
        description     => 'CirrusSearch full_text eqiad 95th percentile latency',
        dashboard_links => ['https://grafana.wikimedia.org/d/000000455/elasticsearch-percentiles?orgId=1&var-cirrus_group=eqiad&var-cluster=elasticsearch&var-exported_cluster=production-search&var-smoothing=1&viewPanel=38'],
        metric          => 'fallbackSeries(useSeriesAbove(transformNull(MediaWiki.CirrusSearch.eqiad.requestTimeMs.comp_suggest.sample_rate, 0), 10, "requestTimeMs.comp_suggest.sample_rate", "requestTimeMs.full_text.p95"), constantLine(0))',
        from            => '10min',
        warning         => 500,
        critical        => 1000,
        percentage      => 20,
        contact_group   => 'team-discovery',
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Search#Health/Activity_Monitoring',
    }

    monitoring::graphite_threshold { 'cirrussearch_codfw_fulltext_95th_percentile':
        description     => 'CirrusSearch full_text codfw 95th percentile latency',
        dashboard_links => ['https://grafana.wikimedia.org/d/000000455/elasticsearch-percentiles?orgId=1&var-cirrus_group=codfw&var-cluster=elasticsearch&var-exported_cluster=production-search&var-smoothing=1&viewPanel=38'],
        metric          => 'fallbackSeries(useSeriesAbove(transformNull(MediaWiki.CirrusSearch.codfw.requestTimeMs.comp_suggest.sample_rate, 0), 10, "requestTimeMs.comp_suggest.sample_rate", "requestTimeMs.full_text.p95"), constantLine(0))',
        from            => '10min',
        warning         => 500,
        critical        => 1000,
        percentage      => 20,
        contact_group   => 'team-discovery',
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Search#Health/Activity_Monitoring',
    }

    monitoring::graphite_threshold { 'cirrussearch_eqiad_compsuggest_95th_percentile':
        description     => 'CirrusSearch comp_suggest eqiad 95th percentile latency',
        dashboard_links => ['https://grafana.wikimedia.org/d/000000455/elasticsearch-percentiles?orgId=1&var-cirrus_group=eqiad&var-cluster=elasticsearch&var-exported_cluster=production-search&var-smoothing=1&viewPanel=50'],
        metric          => 'fallbackSeries(useSeriesAbove(transformNull(MediaWiki.CirrusSearch.eqiad.requestTimeMs.comp_suggest.sample_rate, 0), 10, "requestTimeMs.comp_suggest.sample_rate", "requestTimeMs.comp_suggest.p95"), constantLine(0))',
        from            => '10min',
        warning         => 100,
        critical        => 250,
        percentage      => 20,
        contact_group   => 'team-discovery',
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Search#Health/Activity_Monitoring',
    }

    monitoring::graphite_threshold { 'cirrussearch_codfw_compsuggest_95th_percentile':
        description     => 'CirrusSearch comp_suggest codfw 95th percentile latency',
        dashboard_links => ['https://grafana.wikimedia.org/d/000000455/elasticsearch-percentiles?orgId=1&var-cirrus_group=codfw&var-cluster=elasticsearch&var-exported_cluster=production-search&var-smoothing=1&viewPanel=50'],
        metric          => 'fallbackSeries(useSeriesAbove(transformNull(MediaWiki.CirrusSearch.codfw.requestTimeMs.comp_suggest.sample_rate, 0), 10, "requestTimeMs.comp_suggest.sample_rate", "requestTimeMs.comp_suggest.p95"), constantLine(0))',
        from            => '10min',
        warning         => 100,
        critical        => 250,
        percentage      => 20,
        contact_group   => 'team-discovery',
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Search#Health/Activity_Monitoring',
    }

    monitoring::graphite_threshold { 'cirrussearch_eqiad_morelike_95th_percentile':
        description     => 'CirrusSearch more_like eqiad 95th percentile latency',
        dashboard_links => ['https://grafana.wikimedia.org/d/000000455/elasticsearch-percentiles?orgId=1&var-cirrus_group=eqiad&var-cluster=elasticsearch&var-exported_cluster=production-search&var-smoothing=1&viewPanel=39'],
        metric          => 'fallbackSeries(useSeriesAbove(transformNull(MediaWiki.CirrusSearch.eqiad.requestTimeMs.comp_suggest.sample_rate, 0), 10, "requestTimeMs.comp_suggest.sample_rate", "requestTimeMs.more_like.p95"), constantLine(0))',
        from            => '10min',
        warning         => 1000,
        critical        => 1500,
        percentage      => 20,
        contact_group   => 'team-discovery',
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Search#Health/Activity_Monitoring',
    }

    monitoring::graphite_threshold { 'cirrussearch_codfw_morelike_95th_percentile':
        description     => 'CirrusSearch more_like codfw 95th percentile latency',
        dashboard_links => ['https://grafana.wikimedia.org/d/000000455/elasticsearch-percentiles?orgId=1&var-cirrus_group=codfw&var-cluster=elasticsearch&var-exported_cluster=production-search&var-smoothing=1&viewPanel=39'],
        metric          => 'fallbackSeries(useSeriesAbove(transformNull(MediaWiki.CirrusSearch.codfw.requestTimeMs.comp_suggest.sample_rate, 0), 10, "requestTimeMs.comp_suggest.sample_rate", "requestTimeMs.more_like.p95"), constantLine(0))',
        from            => '10min',
        warning         => 1000,
        critical        => 1500,
        percentage      => 20,
        contact_group   => 'team-discovery',
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Search#Health/Activity_Monitoring',
    }

    # warning level is ~1% of peak traffic failing
    monitoring::graphite_threshold { 'search_backend_failure_count':
        description     => 'Number of backend failures per minute from CirrusSearch',
        dashboard_links => ['https://grafana.wikimedia.org/d/000000455/elasticsearch-percentiles?orgId=1&var-cluster=eqiad&var-smoothing=1&viewPanel=9'],
        metric          => 'transformNull(MediaWiki.CirrusSearch.eqiad.backend_failure.failed.count, 0)',
        from            => '10min',
        warning         => 300,
        critical        => 600,
        percentage      => 20,
        contact_group   => 'team-discovery',
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Search#Health/Activity_Monitoring',
    }

    monitoring::graphite_threshold { 'search_backend_memory_issue_count':
        description     => 'Number of requests triggering circuit breakers due to excessive memory usage',
        dashboard_links => ['https://grafana.wikimedia.org/d/000000455/elasticsearch-percentiles?orgId=1&var-cluster=eqiad&var-smoothing=1&viewPanel=9'],
        metric          => 'transformNull(MediaWiki.CirrusSearch.eqiad.backend_failure.memory_issue.count, 0)',
        from            => '10min',
        warning         => 10,
        critical        => 20,
        percentage      => 20,
        contact_group   => 'team-discovery',
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Search#Health/Activity_Monitoring',
    }
}
