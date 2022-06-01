class profile::prometheus::global (
    Array[Stdlib::Host] $alertmanagers                  = lookup('alertmanagers', {'default_value' => []}),
    Array               $alerting_relabel_configs_extra = lookup('profile::prometheus::global::alerting_relabel_configs_extra'),
){

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
            # Service-level aggregated metrics
            '{__name__=~"^.*:mysql_.*"}',
            '{__name__=~"^.*:memcached_.*"}',
            '{__name__=~"^.*:varnish_.*"}',
            '{__name__=~"^.*:trafficserver_.*"}',
            # blackbox_exporter probes results
            '{__name__=~"^probe_.*"}',
            # Bird prefix export count
            '{__name__="bird_protocol_prefix_export_count"}',
            # Swift container/account stats
            '{__name__=~"^swift_account_stats.*"}',
            '{__name__=~"^swift_container_stats.*"}',
            # IPsec Status metrics
            '{__name__="ipsec_status"}',
            # Global authdns metrics
            '{__name__=~"^gdnsd_.*"}',
          ],
        },
        'static_configs' => [
          { 'targets' => [
              'prometheus.svc.eqiad.wmnet',
              'prometheus.svc.codfw.wmnet',
              'prometheus.svc.ulsfo.wmnet',
              'prometheus.svc.esams.wmnet',
              'prometheus.svc.eqsin.wmnet',
              'prometheus.svc.drmrs.wmnet',
            ],
          },
        ],
        # The following labels are external_labels added for Thanos to pick up.
        # Discard them here for backwards compatibility, and because 'replica'
        # would flip depending on which Prometheus replica replies, creating
        # new metrics in the process.
        'metric_relabel_configs' => [
          { 'regex'         => '(prometheus|replica)',
            'action'        => 'labeldrop',
          },
        ],
      },
    ]

    prometheus::rule { 'rules_global.yml':
        instance => 'global',
        source   => 'puppet:///modules/profile/prometheus/rules_global.yml',
    }

    prometheus::server { 'global':
        # 2.25 years. The extra .25 is to allow for year-over-year comparisons
        storage_retention              => '19656h',
        listen_address                 => '127.0.0.1:9904',
        scrape_configs_extra           => $federation_jobs,
        alertmanagers                  => $alertmanagers.map |$a| { "${a}:9093" },
        alerts_deploy_path             => '/srv/alerts-global',
        alerting_relabel_configs_extra => $alerting_relabel_configs_extra,
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
