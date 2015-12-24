class role::graphite::alerts::reqstats {

    # Monitor production 5xx rates

    $settings = {'warning' => 250, 'critical' => 1000, from => '10min'}

    # sites aggregates
    monitoring::graphite_threshold { 'reqstats-5xx-eqiad':
        description     => 'Eqiad HTTP 5xx reqs/min',
        metric          => 'sumSeries(varnish.eqiad.*.frontend.request.client.status.5xx.sum)',
        warning         => $settings['warning'],
        critical        => $settings['critical'],
        from            => $settings['cron'],
        nagios_critical => false,
    }

    monitoring::graphite_threshold { 'reqstats-5xx-esams':
        description     => 'Esams HTTP 5xx reqs/min',
        metric          => 'sumSeries(varnish.esams.*.frontend.request.client.status.5xx.sum)',
        warning         => $settings['warning'],
        critical        => $settings['critical'],
        from            => $settings['cron'],
        nagios_critical => false,
    }

    monitoring::graphite_threshold { 'reqstats-5xx-codfw':
        description     => 'Codfw HTTP 5xx reqs/min',
        metric          => 'sumSeries(varnish.codfw.*.frontend.request.client.status.5xx.sum)',
        warning         => $settings['warning'],
        critical        => $settings['critical'],
        from            => $settings['cron'],
        nagios_critical => false,
    }

    monitoring::graphite_threshold { 'reqstats-5xx-ulsfo':
        description     => 'Ulsfo HTTP 5xx reqs/min',
        metric          => 'sumSeries(varnish.ulsfo.*.frontend.request.client.status.5xx.sum)',
        warning         => $settings['warning'],
        critical        => $settings['critical'],
        from            => $settings['cron'],
        nagios_critical => false,
    }

    # per-cache aggregates
    monitoring::graphite_threshold { 'reqstats-5xx-text':
        description     => 'Text HTTP 5xx reqs/min',
        metric          => 'sumSeries(varnish.*.text.frontend.request.client.status.5xx.sum)',
        warning         => $settings['warning'],
        critical        => $settings['critical'],
        from            => $settings['cron'],
        nagios_critical => false,
    }

    monitoring::graphite_threshold { 'reqstats-5xx-mobile':
        description     => 'Mobile HTTP 5xx reqs/min',
        metric          => 'sumSeries(varnish.*.mobile.frontend.request.client.status.5xx.sum)',
        warning         => $settings['warning'],
        critical        => $settings['critical'],
        from            => $settings['cron'],
        nagios_critical => false,
    }

    monitoring::graphite_threshold { 'reqstats-5xx-uploads':
        description     => 'Uploads HTTP 5xx reqs/min',
        metric          => 'sumSeries(varnish.*.uploads.frontend.request.client.status.5xx.sum)',
        warning         => $settings['warning'],
        critical        => $settings['critical'],
        from            => $settings['cron'],
        nagios_critical => false,
    }

    monitoring::graphite_threshold { 'reqstats-5xx-misc':
        description     => 'Misc HTTP 5xx reqs/min',
        metric          => 'sumSeries(varnish.*.misc.frontend.request.client.status.5xx.sum)',
        warning         => $settings['warning'],
        critical        => $settings['critical'],
        from            => $settings['cron'],
        nagios_critical => false,
    }

    monitoring::graphite_threshold { 'reqstats-5xx-parsoid':
        description     => 'Parsoid HTTP 5xx reqs/min',
        metric          => 'sumSeries(varnish.*.parsoid.frontend.request.client.status.5xx.sum)',
        warning         => $settings['warning'],
        critical        => $settings['critical'],
        from            => $settings['cron'],
        nagios_critical => false,
    }

    monitoring::graphite_threshold { 'reqstats-5xx-maps':
        description     => 'Maps HTTP 5xx reqs/min',
        metric          => 'sumSeries(varnish.*.maps.frontend.request.client.status.5xx.sum)',
        warning         => $settings['warning'],
        critical        => $settings['critical'],
        from            => $settings['cron'],
        nagios_critical => false,
    }
}

