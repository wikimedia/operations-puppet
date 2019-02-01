class profile::graphite::alerts::reqstats {

    # Monitor production 5xx rates

    $settings = {'warning' => 250, 'critical' => 1000, from => '10min'}

    # sites aggregates
    monitoring::graphite_threshold { 'reqstats-5xx-eqiad':
        description     => 'Eqiad HTTP 5xx reqs/min',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/file/varnish-aggregate-client-status-codes?panelId=3&fullscreen&orgId=1&var-site=eqiad&var-cache_type=All&var-status_type=5'],
        metric          => 'sumSeries(varnish.eqiad.*.frontend.request.client.status.5xx.sum)',
        warning         => $settings['warning'],
        critical        => $settings['critical'],
        from            => $settings['cron'],
        nagios_critical => false,
    }

    monitoring::graphite_threshold { 'reqstats-5xx-esams':
        description     => 'Esams HTTP 5xx reqs/min',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/file/varnish-aggregate-client-status-codes?panelId=3&fullscreen&orgId=1&var-site=esams&var-cache_type=All&var-status_type=5'],
        metric          => 'sumSeries(varnish.esams.*.frontend.request.client.status.5xx.sum)',
        warning         => $settings['warning'],
        critical        => $settings['critical'],
        from            => $settings['cron'],
        nagios_critical => false,
    }

    monitoring::graphite_threshold { 'reqstats-5xx-codfw':
        description     => 'Codfw HTTP 5xx reqs/min',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/file/varnish-aggregate-client-status-codes?panelId=3&fullscreen&orgId=1&var-site=codfw&var-cache_type=All&var-status_type=5'],
        metric          => 'sumSeries(varnish.codfw.*.frontend.request.client.status.5xx.sum)',
        warning         => $settings['warning'],
        critical        => $settings['critical'],
        from            => $settings['cron'],
        nagios_critical => false,
    }

    monitoring::graphite_threshold { 'reqstats-5xx-ulsfo':
        description     => 'Ulsfo HTTP 5xx reqs/min',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/file/varnish-aggregate-client-status-codes?panelId=3&fullscreen&orgId=1&var-site=ulsfo&var-cache_type=All&var-status_type=5'],
        metric          => 'sumSeries(varnish.ulsfo.*.frontend.request.client.status.5xx.sum)',
        warning         => $settings['warning'],
        critical        => $settings['critical'],
        from            => $settings['cron'],
        nagios_critical => false,
    }

    monitoring::graphite_threshold { 'reqstats-5xx-eqsin':
        description     => 'Eqsin HTTP 5xx reqs/min',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/file/varnish-aggregate-client-status-codes?panelId=3&fullscreen&orgId=1&var-site=eqsin&var-cache_type=All&var-status_type=5'],
        metric          => 'sumSeries(varnish.eqsin.*.frontend.request.client.status.5xx.sum)',
        warning         => $settings['warning'],
        critical        => $settings['critical'],
        from            => $settings['cron'],
        nagios_critical => false,
    }

    # per-cache aggregates
    monitoring::graphite_threshold { 'reqstats-5xx-text':
        description     => 'Text HTTP 5xx reqs/min',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/file/varnish-aggregate-client-status-codes?panelId=3&fullscreen&orgId=1&var-site=All&var-cache_type=text&var-status_type=5'],
        metric          => 'sumSeries(varnish.*.text.frontend.request.client.status.5xx.sum)',
        warning         => $settings['warning'],
        critical        => $settings['critical'],
        from            => $settings['cron'],
        nagios_critical => false,
    }

    monitoring::graphite_threshold { 'reqstats-5xx-upload':
        description     => 'Upload HTTP 5xx reqs/min',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/file/varnish-aggregate-client-status-codes?panelId=3&fullscreen&orgId=1&var-site=All&var-cache_type=upload&var-status_type=5'],
        metric          => 'sumSeries(varnish.*.upload.frontend.request.client.status.5xx.sum)',
        warning         => $settings['warning'],
        critical        => $settings['critical'],
        from            => $settings['cron'],
        nagios_critical => false,
    }

}
