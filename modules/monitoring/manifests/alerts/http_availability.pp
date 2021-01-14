# Global frontend HTTP availability
define monitoring::alerts::http_availability(
  $warning  = 99.5,
  $critical = 99.0,
  ) {
    # Varnish HTTP availability as seen by looking at status codes
    monitoring::check_prometheus { "varnish_${title}":
        description     => 'Varnish has reduced HTTP availability',
        query           => '100 * (1 - global_job:varnish_requests:avail2m)',
        prometheus_url  => 'http://prometheus.svc.eqiad.wmnet/global',
        method          => 'le',
        retries         => 2,
        warning         => $warning,
        critical        => $critical,
        nagios_critical => true,
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/frontend-traffic?panelId=3&fullscreen&refresh=1m&orgId=1',
                            'https://logstash.wikimedia.org/goto/fe494e83d04fee66c8f0958bfc28451f'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Varnish#Diagnosing_Varnish_alerts',
    }

    # ATS (on Varnish hosts) HTTP availability as seen by looking at status codes
    monitoring::check_prometheus { "ats_${title}":
        description     => 'ATS TLS has reduced HTTP availability',
        query           => '100 * (1 - global_job:trafficserver_requests:avail2m{layer="tls"})',
        prometheus_url  => 'http://prometheus.svc.eqiad.wmnet/global',
        method          => 'le',
        retries         => 2,
        warning         => $warning,
        critical        => $critical,
        nagios_critical => true,
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/frontend-traffic?panelId=13&fullscreen&refresh=1m&orgId=1'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Cache_TLS_termination',
    }
}
