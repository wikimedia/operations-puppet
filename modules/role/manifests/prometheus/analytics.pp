# Uses the prometheus module and generates the specific configuration
# needed for WMF production
#
# filtertags: labs-project-monitoring
class role::prometheus::analytics {
    system::role { 'prometheus::analytics':
        description => 'Prometheus server (analytics)',
    }

    include ::standard
    include ::profile::base::firewall

    $targets_path = '/srv/prometheus/analytics/targets'
    $storage_retention = hiera('prometheus::server::storage_retention', '4032h')
    $max_chunks_to_persist = hiera('prometheus::server::max_chunks_to_persist', '524288')
    $memory_chunks = hiera('prometheus::server::memory_chunks', '1048576')
    $prometheus_v2 = hiera('prometheus::server::prometheus_v2', false)

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
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/jmx_druid_*.yaml" ]}
        ],
      },
      {
        'job_name'        => 'jmx_hadoop',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/jmx_hadoop_*.yaml" ]}
        ],
      },
      {
        'job_name'        => 'jmx_hive',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/jmx_hive_*.yaml" ]}
        ],
      },
      {
        'job_name'        => 'cassandra',
        'scrape_timeout'  => '25s',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/jmx_aqs_cassandra_*.yaml" ]}
        ],
        # Drop restbase table/cf 'meta' metrics, not needed
        'metric_relabel_configs' => [
          { 'source_labels' => ['columnfamily'],
            'regex'  => 'meta',
            'action' => 'drop',
          },
          { 'source_labels' => ['table'],
            'regex'  => 'meta',
            'action' => 'drop',
          },
          # rename columnfamily to table, in metric names and labels.
          # T193017
          { 'source_labels' => ['columnfamily'],
            'regex' => '(.*)',
            'action' => 'replace',
            'target_label' => 'table',
            'replacement' => '$1',
          },
          { 'regex'  => 'columnfamily',
            'action' => 'labeldrop',
          },
          { 'source_labels' => ['__name__'],
            'regex' => 'cassandra_columnfamily_(.*)',
            'action' => 'replace',
            'target_label' => '__name__',
            'replacement' => 'cassandra_table_$1',
          },
        ],
      },
    ]

    $mysql_jobs = [
      {
        'job_name'        => 'mysql-databases',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/mysql_database_*.yaml"] },
        ]
      },
    ]

    prometheus::class_config{ "matomo_mysql_${::site}":
        dest       => "${targets_path}/mysql_database_matomo_${::site}.yaml",
        site       => $::site,
        class_name => 'role::piwik',
        port       => 13306,
    }

    prometheus::class_config{ "analyics_meta_mysql_${::site}":
        dest       => "${targets_path}/mysql_database_analyics_meta_${::site}.yaml",
        site       => $::site,
        class_name => 'profile::analytics::database::meta',
        port       => 13306,
    }

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

    prometheus::jmx_exporter_config{ "hadoop_worker_test_${::site}":
        dest       => "${targets_path}/jmx_hadoop_worker_test_${::site}.yaml",
        class_name => 'role::analytics_test_cluster::hadoop::worker',
        site       => $::site,
    }

    prometheus::jmx_exporter_config{ "hadoop_master_test_${::site}":
        dest       => "${targets_path}/jmx_hadoop_master_test_${::site}.yaml",
        class_name => 'role::analytics_test_cluster::hadoop::master',
        site       => $::site,
    }

    prometheus::jmx_exporter_config{ "hadoop_standby_test_${::site}":
        dest       => "${targets_path}/jmx_hadoop_standby_test_${::site}.yaml",
        class_name => 'role::analytics_test_cluster::hadoop::standby',
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

    prometheus::jmx_exporter_config{ "hive_analytics_${::site}":
        dest       => "${targets_path}/jmx_hive_analytics_${::site}.yaml",
        class_name => 'role::analytics_cluster::coordinator',
        site       => $::site,
    }

    prometheus::jmx_exporter_config{ "cassandra_aqs_${::site}":
        dest       => "${targets_path}/jmx_aqs_cassandra_${::site}.yaml",
        class_name => 'role::aqs',
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
        port    => 8000,
        labels  => {
            'cluster' => 'druid_public'
        }
    }

    prometheus::cluster_config{ "druid_analytics_${::site}":
        dest    => "${targets_path}/druid_analytics_${::site}.yaml",
        site    => $::site,
        cluster => 'druid_analytics',
        port    => 8000,
        labels  => {
            'cluster' => 'druid_analytics'
        }
    }

    $kafka_burrow_jobs = [
      {
        'job_name'        => 'burrow',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/burrow_*.yaml" ]}
        ],
      },
    ]

    prometheus::class_config{ "burrow_analytics_${::site}":
        dest       => "${targets_path}/burrow_analytics_${::site}.yaml",
        site       => $::site,
        class_name => 'role::kafka::monitoring',
        port       => 9000,
    }

    prometheus::server { 'analytics':
        listen_address        => '127.0.0.1:9905',
        storage_retention     => $storage_retention,
        max_chunks_to_persist => $max_chunks_to_persist,
        memory_chunks         => $memory_chunks,
        global_config_extra   => $config_extra,
        scrape_configs_extra  => array_concat($jmx_exporter_jobs, $druid_jobs, $kafka_burrow_jobs, $mysql_jobs),
        prometheus_v2         => $prometheus_v2,
    }

    prometheus::web { 'analytics':
        proxy_pass => 'http://localhost:9905/analytics',
    }

    if $prometheus_v2 {
        prometheus::rule { 'rules_analytics.yml':
            instance => 'analytics',
            source   => 'puppet:///modules/role/prometheus/rules_analytics.yml',
        }
    } else {
        prometheus::rule { 'rules_analytics.conf':
            instance => 'analytics',
            source   => 'puppet:///modules/role/prometheus/rules_analytics.conf',
        }
    }
}
