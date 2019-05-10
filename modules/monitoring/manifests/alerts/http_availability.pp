# Setup alerting for Varnish and Nginx availability for the given site.
define monitoring::alerts::http_availability(
  $site,
  $warning  = 99.95,
  $critical = 99.93,
  ) {
    # Varnish HTTP availability as seen by looking at status codes
    monitoring::check_prometheus { "varnish_${title}":
        description     => "HTTP availability for Varnish at ${site}",
        query           => "100 * (1 - site_job:varnish_requests:avail5m{job=~\"varnish-(text|upload)\",site=\"${site}\"})",
        prometheus_url  => 'http://prometheus.svc.eqiad.wmnet/global',
        method          => 'le',
        retries         => 1,
        warning         => $warning,
        critical        => $critical,
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/frontend-traffic?panelId=3&fullscreen&refresh=1m&orgId=1'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Varnish#Diagnosing_Varnish_alerts',
    }

    # Nginx (on Varnish hosts) HTTP availability as seen by looking at status codes
    monitoring::check_prometheus { "nginx_${title}":
        description     => "HTTP availability for Nginx (SSL terminators) at ${site}",
        query           => "100 * (1 - site_cluster:nginx_requests:avail5m{cluster=~\"cache_(text|upload)\",site=\"${site}\"})",
        prometheus_url  => 'http://prometheus.svc.eqiad.wmnet/global',
        method          => 'le',
        retries         => 1,
        warning         => $warning,
        critical        => $critical,
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/frontend-traffic?panelId=4&fullscreen&refresh=1m&orgId=1'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Cache_TLS_termination',
    }
}
