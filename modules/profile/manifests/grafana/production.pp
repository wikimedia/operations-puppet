# == Class: profile::grafana::production
#
# Grafana is a dashboarding webapp for Graphite.
# It powers <https://grafana.wikimedia.org>.
#
class profile::grafana::production {
    require ::profile::grafana

    grafana::dashboard { 'varnish-http-errors':
        source => 'puppet:///modules/grafana/dashboards/varnish-http-errors',
    }

    grafana::dashboard { 'varnish-aggregate-client-status-codes':
        source => 'puppet:///modules/grafana/dashboards/varnish-aggregate-client-status-codes',
    }

    grafana::dashboard { 'swift':
        source => 'puppet:///modules/grafana/dashboards/swift',
    }
    grafana::dashboard { 'server-board':
        source => 'puppet:///modules/grafana/dashboards/server-board',
    }
}
