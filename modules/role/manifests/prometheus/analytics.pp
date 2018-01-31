# Uses the prometheus module and generates the specific configuration
# needed for WMF production
#
# filtertags: labs-project-monitoring
class role::prometheus::analytics {
    system::role { 'prometheus::analytics':
        description => 'Prometheus server (analytics)',
    }

    include ::standard
    include ::base::firewall

    $targets_path = '/srv/prometheus/analytics/targets'
    $storage_retention = hiera('prometheus::server::storage_retention', '2190h0m0s')
    $max_chunks_to_persist = hiera('prometheus::server::max_chunks_to_persist', '524288')
    $memory_chunks = hiera('prometheus::server::memory_chunks', '1048576')

    $config_extra = {
        # All metrics will get an additional 'site' label when queried by
        # external systems (e.g. via federation)
        'external_labels' => {
            'site' => $::site,
        },
    }

    $jmx_exporter_jobs = [
      {
        'job_name'        => 'jmx_druid',
        'scrape_timeout'  => '25s',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/jmx_druid_*.yaml" ]}
        ],
      },
      {
        'job_name'        => 'jmx_hadoop',
        'scrape_timeout'  => '25s',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/jmx_hadoop_*.yaml" ]}
        ],
      },
    ]

    prometheus::jmx_exporter_config{ "hadoop_worker_${::site}":
        dest       => "${targets_path}/jmx_hadoop_worker_${::site}.yaml",
        class_name => 'role::analytics_cluster::hadoop::worker',
        site       => $::site,
    }

    prometheus::jmx_exporter_config{ "hadoop_master_${::site}":
        dest       => "${targets_path}/jmx_hadoop_master_${::site}.yaml",
        class_name => 'role::analytics_cluster::hadoop::master',
        site       => $::site,
    }

    prometheus::jmx_exporter_config{ "hadoop_standby_${::site}":
        dest       => "${targets_path}/jmx_hadoop_standby_${::site}.yaml",
        class_name => 'role::analytics_cluster::hadoop::standby',
        site       => $::site,
    }

    prometheus::jmx_exporter_config{ "druid_public_${::site}":
        dest       => "${targets_path}/jmx_druid_public_${::site}.yaml",
        class_name => 'role::druid::public::worker',
        site       => $::site,
    }

    prometheus::jmx_exporter_config{ "druid_analytics_${::site}":
        dest       => "${targets_path}/jmx_druid_analytics_${::site}.yaml",
        class_name => 'role::druid::analytics::worker',
        site       => $::site,
    }

    # Job definition for druid_exporter
    $druid_jobs = [
      {
        'job_name'        => 'druid',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/druid_*.yaml"] },
        ]
      },
    ]

    prometheus::cluster_config{ "druid_public_${::site}":
        dest    => "${targets_path}/druid_public_${::site}.yaml",
        site    => $::site,
        cluster => 'druid_public',
        port    => '8000',
        labels  => {
            'cluster' => 'druid_public'
        }
    }

    prometheus::cluster_config{ "druid_analytics_${::site}":
        dest    => "${targets_path}/druid_analytics_${::site}.yaml",
        site    => $::site,
        cluster => 'druid_analytics',
        port    => '8000',
        labels  => {
            'cluster' => 'druid_analytics'
        }
    }

    prometheus::server { 'analytics':
        listen_address        => '127.0.0.1:9905',
        storage_retention     => $storage_retention,
        max_chunks_to_persist => $max_chunks_to_persist,
        memory_chunks         => $memory_chunks,
        global_config_extra   => $config_extra,
        scrape_configs_extra  => array_concat($jmx_exporter_jobs, $druid_jobs)
    }

    prometheus::web { 'analytics':
        proxy_pass => 'http://localhost:9905/analytics',
    }

    prometheus::rule { 'rules_analytics.conf':
        instance => 'analytics',
        source   => 'puppet:///modules/role/prometheus/rules_analytics.conf',
    }
}
