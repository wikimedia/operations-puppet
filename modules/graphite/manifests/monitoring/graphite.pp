# == Class: graphite::monitoring::graphite
#
# Monitor a graphite stack for important vitals, namely what it is interesting
# if we are losing data and how much.
# To that end, both "carbon-relay" (what accepts metrics from the outside) and
# "carbon-cache" (what read/writes datapoints from/to disk) are monitored, e.g.
# if there is any dropping of datapoints in their queues or errors otherwise.

class graphite::monitoring::graphite {
    monitoring::graphite_threshold { 'carbon-frontend-relay_drops':
        description     => 'carbon-frontend-relay metric drops',
        dashboard_links => [
            'https://grafana.wikimedia.org/dashboard/db/graphite-eqiad?orgId=1&panelId=21&fullscreen',
            'https://grafana.wikimedia.org/dashboard/db/graphite-codfw?orgId=1&panelId=21&fullscreen',
        ],
        metric          => 'sumSeries(transformNull(perSecond(carbon.relays.graphite*_frontend.destinations.*.dropped)))',
        from            => '5minutes',
        warning         => 25,
        critical        => 100,
        percentage      => 80,
        nagios_critical => false,
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Graphite#Operations_troubleshooting',
    }

    monitoring::graphite_threshold { 'carbon-local-relay_drops':
        description     => 'carbon-local-relay metric drops',
        dashboard_links => [
            'https://grafana.wikimedia.org/dashboard/db/graphite-eqiad?orgId=1&panelId=29&fullscreen',
            'https://grafana.wikimedia.org/dashboard/db/graphite-codfw?orgId=1&panelId=29&fullscreen',
        ],
        metric          => 'sumSeries(transformNull(perSecond(carbon.relays.graphite*_local.destinations.*.dropped)))',
        from            => '5minutes',
        warning         => 25,
        critical        => 100,
        percentage      => 80,
        nagios_critical => false,
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Graphite#Operations_troubleshooting',
    }

    # is carbon-cache able to write to disk (e.g. permissions)
    monitoring::graphite_threshold { 'carbon-cache_write_error':
        description     => 'carbon-cache write error',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/graphite-eqiad?orgId=1&panelId=30&fullscreen'],
        metric          => 'secondYAxis(sumSeries(carbon.agents.graphite1004-*.errors))',
        from            => '10minutes',
        warning         => 1,
        critical        => 8,
        percentage      => 80,
        nagios_critical => false,
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Graphite#Operations_troubleshooting',
    }

    # are carbon-cache queues overflowing their capacity?
    monitoring::graphite_threshold { 'carbon-cache_overflow':
        description     => 'carbon-cache queues overflow',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/graphite-eqiad?orgId=1&panelId=8&fullscreen'],
        metric          => 'secondYAxis(sumSeries(carbon.agents.graphite1004-*.cache.overflow))',
        from            => '10minutes',
        warning         => 1,
        critical        => 8,
        percentage      => 80,
        nagios_critical => false,
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Graphite#Operations_troubleshooting',
    }

    # are we creating too many metrics?
    monitoring::graphite_threshold { 'carbon-cache_many_creates':
        description     => 'carbon-cache too many creates',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/graphite-eqiad?orgId=1&panelId=9&fullscreen'],
        metric          => 'sumSeries(carbon.agents.graphite1004-*.creates)',
        from            => '30min',
        warning         => 500,
        critical        => 1000,
        nagios_critical => false,
        percentage      => 80,
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Graphite#Operations_troubleshooting',
    }
}
