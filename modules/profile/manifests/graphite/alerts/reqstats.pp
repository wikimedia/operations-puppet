class profile::graphite::alerts::reqstats($graphite_url = hiera('graphite_url')) {
    Monitoring::Graphite_threshold {
        graphite_url => $graphite_url
    }

    # Monitor production 5xx rates

    $settings = {'warning' => 250, 'critical' => 1000, from => '10min'}

    # sites aggregates
    monitoring::graphite_threshold { 'reqstats-5xx-eqiad':
        description     => 'Eqiad HTTP 5xx reqs/min',
        dashboard_links => ['https://grafana.wikimedia.org/d/myRmf1Pik/varnish-aggregate-client-status-codes?var-site=eqiad&var-status_type=5'],
        metric          => 'sumSeries(varnish.eqiad.*.frontend.request.client.status.5xx.sum)',
        warning         => $settings['warning'],
        critical        => $settings['critical'],
        from            => $settings['cron'],
        nagios_critical => false,
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Varnish#Diagnosing_Varnish_alerts',
    }

    monitoring::graphite_threshold { 'reqstats-5xx-esams':
        description     => 'Esams HTTP 5xx reqs/min',
        dashboard_links => ['https://grafana.wikimedia.org/d/myRmf1Pik/varnish-aggregate-client-status-codes?var-site=esams&var-status_type=5'],
        metric          => 'sumSeries(varnish.esams.*.frontend.request.client.status.5xx.sum)',
        warning         => $settings['warning'],
        critical        => $settings['critical'],
        from            => $settings['cron'],
        nagios_critical => false,
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Varnish#Diagnosing_Varnish_alerts',
    }

    monitoring::graphite_threshold { 'reqstats-5xx-codfw':
        description     => 'Codfw HTTP 5xx reqs/min',
        dashboard_links => ['https://grafana.wikimedia.org/d/myRmf1Pik/varnish-aggregate-client-status-codes?var-site=codfw&var-status_type=5'],
        metric          => 'sumSeries(varnish.codfw.*.frontend.request.client.status.5xx.sum)',
        warning         => $settings['warning'],
        critical        => $settings['critical'],
        from            => $settings['cron'],
        nagios_critical => false,
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Varnish#Diagnosing_Varnish_alerts',
    }

    monitoring::graphite_threshold { 'reqstats-5xx-ulsfo':
        description     => 'Ulsfo HTTP 5xx reqs/min',
        dashboard_links => ['https://grafana.wikimedia.org/d/myRmf1Pik/varnish-aggregate-client-status-codes?var-site=ulsfo&var-status_type=5'],
        metric          => 'sumSeries(varnish.ulsfo.*.frontend.request.client.status.5xx.sum)',
        warning         => $settings['warning'],
        critical        => $settings['critical'],
        from            => $settings['cron'],
        nagios_critical => false,
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Varnish#Diagnosing_Varnish_alerts',
    }

    monitoring::graphite_threshold { 'reqstats-5xx-eqsin':
        description     => 'Eqsin HTTP 5xx reqs/min',
        dashboard_links => ['https://grafana.wikimedia.org/d/myRmf1Pik/varnish-aggregate-client-status-codes?var-site=eqsin&var-status_type=5'],
        metric          => 'sumSeries(varnish.eqsin.*.frontend.request.client.status.5xx.sum)',
        warning         => $settings['warning'],
        critical        => $settings['critical'],
        from            => $settings['cron'],
        nagios_critical => false,
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Varnish#Diagnosing_Varnish_alerts',
    }

    # per-cache aggregates
    monitoring::graphite_threshold { 'reqstats-5xx-text':
        description     => 'Text HTTP 5xx reqs/min',
        dashboard_links => ['https://grafana.wikimedia.org/d/myRmf1Pik/varnish-aggregate-client-status-codes?var-cache_type=varnish-text&var-status_type=5'],
        metric          => 'sumSeries(varnish.*.text.frontend.request.client.status.5xx.sum)',
        warning         => $settings['warning'],
        critical        => $settings['critical'],
        from            => $settings['cron'],
        nagios_critical => false,
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Varnish#Diagnosing_Varnish_alerts',
    }

    monitoring::graphite_threshold { 'reqstats-5xx-upload':
        description     => 'Upload HTTP 5xx reqs/min',
        dashboard_links => ['https://grafana.wikimedia.org/d/myRmf1Pik/varnish-aggregate-client-status-codes?var-cache_type=varnish-upload&var-status_type=5'],
        metric          => 'sumSeries(varnish.*.upload.frontend.request.client.status.5xx.sum)',
        warning         => $settings['warning'],
        critical        => $settings['critical'],
        from            => $settings['cron'],
        nagios_critical => false,
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Varnish#Diagnosing_Varnish_alerts',
    }
}
