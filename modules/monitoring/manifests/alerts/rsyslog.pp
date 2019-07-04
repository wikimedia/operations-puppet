define monitoring::alerts::rsyslog(
  $site
) {
    monitoring::check_prometheus { "rsyslog-delivery-fail-${site}":
        description     => "rsyslog in ${site} is failing to deliver messages",
        dashboard_links => ["https://grafana.wikimedia.org/d/000000596/rsyslog?var-datasource=${site} prometheus/ops"],
        query           => 'sum by (action) (rate(rsyslog_action_suspended[5m]) + rate(rsyslog_action_failed[5m]))',
        warning         => 5,
        critical        => 10,
        retries         => 5,
        method          => 'ge',
        prometheus_url  => "http://prometheus.svc.${site}.wmnet/ops",
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Rsyslog',
    }
}
