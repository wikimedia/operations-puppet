class role::prometheus::global {
    include base::firewall

    # Pull selected metrics from all DC-local Prometheus servers.
    $federation_jobs = [
      {
        'job_name'        => 'federate-ops',
        'honor_labels'    => true,
        'metrics_path'    => '/federate',
        'params'          => {
          # Pull the union of metrics matching the following queries.
          'match[]' => [
            # Up status for targets and exporters
            '{__name__=~"up"}',
            '{__name__=~"^([a-z_]+)_up"}',
            # Self-monitoring job
            '{job="prometheus"}',
            # Per-cluster aggregated metrics
            '{__name__=~"^cluster:"}',
            '{__name__=~"^cluster_device:"}',
          ],
        },
        'static_config' => [
          'targets' => [
            'prometheus.svc.eqiad.wmnet/ops',
            'prometheus.svc.codfw.wmnet/ops',
            'prometheus.svc.ulsfo.wmnet/ops',
            'prometheus.svc.esams.wmnet/ops',
          ],
        ],
      },
    ]

    prometheus::server { 'global':
        listen_address       => '127.0.0.1:9904',
        scrape_configs_extra => $federation_jobs,
    }

    prometheus::web { 'global':
        proxy_pass => 'http://localhost:9904/global',
    }

    ferm::service { 'prometheus-web-global':
        proto  => 'tcp',
        port   => '80',
        srange => '$DOMAIN_NETWORKS',
    }
}
