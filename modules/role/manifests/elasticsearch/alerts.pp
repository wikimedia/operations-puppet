class role::elasticsearch::alerts {
    monitoring::graphite_threshold { 'prefix_search_50th_percentile':
        description    => 'Prefix search 50th percentile latency',
        metric         => 'transformNull(MediaWiki.CirrusSearch.requestTimeMs.prefix.p50, 0)',
        from           => '10min',
        warning        => '75',
        critical       => '150',
        percentage     => '20',
        contact_group  => 'team-discovery',
    }
}
