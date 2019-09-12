define monitoring::alerts::aggregate_ipsec(
  $site
) {

    monitoring::check_prometheus { "aggregate-ipsec-tunnel-status-${site}":
        description     => "Aggregate IPsec Tunnel Status ${site}",
        dashboard_links => ['https://grafana.wikimedia.org/d/B9JpocKZz/ipsec-tunnel-status'],
        # A value of 4+ represents ignored, so exclude this from the query
        query           => 'sum (ipsec_status) by (instance,tunnel,site) < 4',
        warning         => 1,
        critical        => 2,
        method          => 'ge',
        prometheus_url  => "http://prometheus.svc.${site}.wmnet/ops",
    }

}
