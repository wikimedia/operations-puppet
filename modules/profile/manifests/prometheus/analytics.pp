# Uses the prometheus module and generates the specific configuration
# needed for WMF production
#
class profile::prometheus::analytics (
    String $replica_label              = lookup('prometheus::replica_label', { 'default_value' => 'unset' }),
    Boolean $enable_thanos_upload      = lookup('profile::prometheus::enable_thanos_upload', { 'default_value' => false }),
    Optional[String] $thanos_min_time  = lookup('profile::prometheus::thanos::min_time', { 'default_value' => undef }),
    Array[Stdlib::Host] $alertmanagers = lookup('alertmanagers', {'default_value' => []}),
    String $storage_retention          = lookup('prometheus::server::storage_retention', {'default_value' => '4032h'}),
    Integer $max_chunks_to_persist     = lookup('prometheus::server::max_chunks_to_persist', {'default_value' => 524288}),
    Integer $memory_chunks             = lookup('prometheus::server::memory_chunks', {'default_value' => 1048576}),
    Boolean $disable_compaction        = lookup('profile::prometheus::thanos::disable_compaction', { 'default_value' => false }),
){

    $targets_path = '/srv/prometheus/analytics/targets'

    $config_extra = {
        # All metrics will get an additional 'site' label when queried by
        # external systems (e.g. via federation)
        'external_labels' => {
            'site'       => $::site,
            'replica'    => $replica_label,
            'prometheus' => 'analytics',
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
        'job_name'        => 'jmx_zookeeper',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/jmx_zookeeper_*.yaml" ]}
        ],
      },
      {
        'job_name'        => 'jmx_presto',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/jmx_presto_*.yaml" ]}
        ],
      },
      {
        'job_name'        => 'cassandra',
        'scrape_timeout'  => '25s',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/jmx_aqs_cassandra_*.yaml",
                          "${targets_path}/jmx_aqs_next_cassandra_*.yaml" ]
          }
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
        'job_name'        => 'mysql-analytics',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/mysql_analytics_*.yaml"] },
        ]
      },
    ]

    prometheus::class_config{ "matomo_mysql_${::site}":
        dest       => "${targets_path}/mysql_analytics_matomo_${::site}.yaml",
        class_name => 'role::piwik',
        port       => 9104,
    }

    prometheus::class_config{ "analyics_meta_mysql_${::site}":
        dest       => "${targets_path}/mysql_analytics_meta_${::site}.yaml",
        class_name => 'profile::analytics::database::meta',
        port       => 9104,
    }

    prometheus::jmx_exporter_config{ "hadoop_worker_${::site}":
        dest       => "${targets_path}/jmx_hadoop_worker_${::site}.yaml",
        class_name => 'role::analytics_cluster::hadoop::worker',
    }

    prometheus::jmx_exporter_config{ "hadoop_master_${::site}":
        dest       => "${targets_path}/jmx_hadoop_master_${::site}.yaml",
        class_name => 'role::analytics_cluster::hadoop::master',
    }

    prometheus::jmx_exporter_config{ "hadoop_standby_${::site}":
        dest       => "${targets_path}/jmx_hadoop_standby_${::site}.yaml",
        class_name => 'role::analytics_cluster::hadoop::standby',
    }

    prometheus::jmx_exporter_config{ "hadoop_worker_test_${::site}":
        dest       => "${targets_path}/jmx_hadoop_worker_test_${::site}.yaml",
        class_name => 'role::analytics_test_cluster::hadoop::worker',
    }

    prometheus::jmx_exporter_config{ "hadoop_master_test_${::site}":
        dest       => "${targets_path}/jmx_hadoop_master_test_${::site}.yaml",
        class_name => 'role::analytics_test_cluster::hadoop::master',
    }

    prometheus::jmx_exporter_config{ "hadoop_standby_test_${::site}":
        dest       => "${targets_path}/jmx_hadoop_standby_test_${::site}.yaml",
        class_name => 'role::analytics_test_cluster::hadoop::standby',
    }

    prometheus::jmx_exporter_config{ "hadoop_worker_backup_${::site}":
        dest       => "${targets_path}/jmx_hadoop_worker_backup_${::site}.yaml",
        class_name => 'role::analytics_backup_cluster::hadoop::worker',
    }

    prometheus::jmx_exporter_config{ "hadoop_master_backup_${::site}":
        dest       => "${targets_path}/jmx_hadoop_master_backup_${::site}.yaml",
        class_name => 'role::analytics_backup_cluster::hadoop::master',
    }

    prometheus::jmx_exporter_config{ "hadoop_standby_backup_${::site}":
        dest       => "${targets_path}/jmx_hadoop_standby_backup_${::site}.yaml",
        class_name => 'role::analytics_backup_cluster::hadoop::standby',
    }

    prometheus::jmx_exporter_config{ "druid_public_${::site}":
        dest       => "${targets_path}/jmx_druid_public_${::site}.yaml",
        class_name => 'role::druid::public::worker',
    }

    prometheus::jmx_exporter_config{ "druid_analytics_${::site}":
        dest       => "${targets_path}/jmx_druid_analytics_${::site}.yaml",
        class_name => 'role::druid::analytics::worker',
    }

    prometheus::jmx_exporter_config{ "hive_analytics_${::site}":
        dest       => "${targets_path}/jmx_hive_analytics_${::site}.yaml",
        class_name => 'profile::hive::server',
    }

    prometheus::jmx_exporter_config{ "cassandra_aqs_${::site}":
        dest       => "${targets_path}/jmx_aqs_cassandra_${::site}.yaml",
        class_name => 'role::aqs',
    }

    prometheus::jmx_exporter_config{ "cassandra_aqs_next_${::site}":
        dest       => "${targets_path}/jmx_aqs_next_cassandra_${::site}.yaml",
        class_name => 'role::aqs_next',
    }

    prometheus::jmx_exporter_config{ "zookeeper_analytics_${::site}":
        dest       => "${targets_path}/jmx_zookeeper_analytics_${::site}.yaml",
        class_name => 'role::analytics_cluster::zookeeper',
    }

    prometheus::jmx_exporter_config{ "presto_analytics_${::site}":
        dest       => "${targets_path}/jmx_presto_analytics_${::site}.yaml",
        class_name => 'role::analytics_cluster::presto::server',
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
        cluster => 'druid_public',
        port    => 8000,
        labels  => {
            'cluster' => 'druid_public'
        }
    }

    prometheus::cluster_config{ "druid_analytics_${::site}":
        dest    => "${targets_path}/druid_analytics_${::site}.yaml",
        cluster => 'druid_analytics',
        port    => 8000,
        labels  => {
            'cluster' => 'druid_analytics'
        }
    }

    $max_block_duration = ($enable_thanos_upload and $disable_compaction) ? {
        true    => '2h',
        default => '24h',
    }

    prometheus::server { 'analytics':
        listen_address        => '127.0.0.1:9905',
        storage_retention     => $storage_retention,
        max_chunks_to_persist => $max_chunks_to_persist,
        memory_chunks         => $memory_chunks,
        global_config_extra   => $config_extra,
        scrape_configs_extra  => [$jmx_exporter_jobs, $druid_jobs, $mysql_jobs].flatten,
        min_block_duration    => '2h',
        max_block_duration    => $max_block_duration,
        alertmanagers         => $alertmanagers.map |$a| { "${a}:9093" },
    }

    prometheus::web { 'analytics':
        proxy_pass => 'http://localhost:9905/analytics',
    }

    profile::thanos::sidecar { 'analytics':
        prometheus_port     => 9905,
        prometheus_instance => 'analytics',
        enable_upload       => $enable_thanos_upload,
        min_time            => $thanos_min_time,
    }

    prometheus::rule { 'rules_analytics.yml':
        instance => 'analytics',
        source   => 'puppet:///modules/profile/prometheus/rules_analytics.yml',
    }
}
