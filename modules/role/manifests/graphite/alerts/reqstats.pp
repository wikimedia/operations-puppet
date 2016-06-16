class role::graphite::alerts::reqstats {

    # Monitor production 5xx rates

    $default_settings = {
        warning         => 250,
        critical        => 1000,
        from            => '10min',
        nagios_critical => false
    }

    $sites_aggregates = {
        'reqstats-5xx-eqiad' => {
            description => 'Eqiad HTTP 5xx reqs/min',
            metric      => 'sumSeries(varnish.eqiad.*.frontend.request.client.status.5xx.sum)',
        },
        'reqstats-5xx-esams' => {
            description => 'Esams HTTP 5xx reqs/min',
            metric      => 'sumSeries(varnish.esams.*.frontend.request.client.status.5xx.sum)',
        },
        'reqstats-5xx-codfw' => {
            description => 'Codfw HTTP 5xx reqs/min',
            metric      => 'sumSeries(varnish.codfw.*.frontend.request.client.status.5xx.sum)',
        },
        'reqstats-5xx-ulsfo' => {
            description => 'Ulsfo HTTP 5xx reqs/min',
            metric      => 'sumSeries(varnish.ulsfo.*.frontend.request.client.status.5xx.sum)',
        },
    }

    $per_cache_aggregates = {
        'reqstats-5xx-text' => {
            description => 'Text HTTP 5xx reqs/min',
            metric      => 'sumSeries(varnish.*.text.frontend.request.client.status.5xx.sum)',
        },
        'reqstats-5xx-uploads' => {
            description => 'Uploads HTTP 5xx reqs/min',
            metric      => 'sumSeries(varnish.*.uploads.frontend.request.client.status.5xx.sum)',
        },
        'reqstats-5xx-misc' => {
            description => 'Misc HTTP 5xx reqs/min',
            metric      => 'sumSeries(varnish.*.misc.frontend.request.client.status.5xx.sum)',
        },
        'reqstats-5xx-maps' => {
            description   => 'Maps HTTP 5xx reqs/min',
            metric        => 'sumSeries(varnish.*.maps.frontend.request.client.status.5xx.sum)',
            contact_group => 'admins,interactive-team',
        },
    }

    create_resources(
        monitoring::graphite_threshold,
        $site_aggregates,
        $default_settings,
    )
    create_resources(
        monitoring::graphite_threshold,
        $cache_aggregates,
        $default_settings,
    )
}
