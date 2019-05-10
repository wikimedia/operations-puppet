# Computes the percentage difference of Varnish GET to text cluster
# Between 30min ago and now.
# Alerts warning at 70% drop, critical at 60.
define monitoring::alerts::traffic_drop(
  $site,
  ) {
    monitoring::check_prometheus { $title:
        description     => "Varnish traffic drop between 30min ago and now at ${site}",
        query           => "sum(job_method_status:varnish_requests:rate5m{method=\"GET\",job=\"varnish-text\", site=\"${site}\"}) * 100 / sum(job_method_status:varnish_requests:rate5m{method=\"GET\",job=\"varnish-text\", site=\"${site}\"} offset 30m)",
        prometheus_url  => 'http://prometheus.svc.eqiad.wmnet/global',
        method          => 'le',
        retries         => 2,
        warning         => 70,
        critical        => 60,
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/varnish-http-requests?panelId=6&fullscreen&orgId=1'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Varnish#Diagnosing_Varnish_alerts',
    }
}
