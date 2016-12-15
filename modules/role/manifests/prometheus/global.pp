class role::prometheus::global {
    include base::firewall

    # Pull selected metrics from all DC-local Prometheus servers.
    $federation_jobs = [
      {
        'job_name'        => 'federate-ops',
        'honor_labels'    => true,
        'metrics_path'    => '/ops/federate',
        'params'          => {
          # Pull the union of metrics matching the following queries.
          # Note: all regexps are implicitly anchored with ^$
          'match[]' => [
            # Up status for targets and exporters
            '{__name__=~"up"}',
            '{__name__=~"^([a-z_]+)_up"}',
            # Self-monitoring job
            '{job="prometheus"}',
            # Per-cluster aggregated metrics
            '{__name__=~"^cluster.*:.*"}',
            '{__name__=~"^instance.*:.*"}',
            # Version stats for auditing purposes
            '{__name__="node_uname_info"}',
            '{__name__="node_exporter_build_info"}',
            '{__name__="varnish_version"}',
            '{__name__="mysql_version_info"}',
            '{__name__="mysqld_exporter_build_info"}',
            '{__name__="memcached_version"}',
            '{__name__="hhvm_build_info"}',
          ],
        },
        'static_configs' => [
          { 'targets' => [
              'prometheus.svc.eqiad.wmnet',
              'prometheus.svc.codfw.wmnet',
              'prometheus.svc.ulsfo.wmnet',
              'prometheus.svc.esams.wmnet',
            ],
          },
        ],
      },
    ]

    prometheus::server { 'global':
        # one year
        storage_retention    => '8760h0m0s',
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
