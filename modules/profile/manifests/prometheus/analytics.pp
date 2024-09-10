# SPDX-License-Identifier: Apache-2.0
# Uses the prometheus module and generates the specific configuration
# needed for WMF production
#
# Configures prometheus for hosts owned by the Data Platform Engineering group,
# formerly known as 'analytics' (which is why this name appears so
# frequently in the config).

class profile::prometheus::analytics (
    String $replica_label              = lookup('prometheus::replica_label'),
    Boolean $enable_thanos_upload      = lookup('profile::prometheus::enable_thanos_upload', { 'default_value' => false }),
    Optional[String] $thanos_min_time  = lookup('profile::prometheus::thanos::min_time', { 'default_value' => undef }),
    Array[Stdlib::Host] $alertmanagers = lookup('alertmanagers', {'default_value' => []}),
    String $storage_retention          = lookup('profile::prometheus::analytics::storage_retention', {'default_value' => '4032h'}),
){

    $targets_path = '/srv/prometheus/analytics/targets'
    $port = 9905

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
          { 'files' => [ "${targets_path}/jmx_aqs_cassandra_*.yaml" ]
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

    $ceph_jobs = [
      {
        'job_name'        => 'ceph',
        'scheme'          => 'http',
        'file_sd_configs' => [
                { 'files' => [ "${targets_path}/ceph_*.yaml" ]}
            ],
            'metric_relabel_configs' => [
                $hostname_to_instance_config,
            ],
      },
    ]

    $hostname_to_instance_config = {
        'source_labels' => ['hostname', 'instance'],
        'separator'     => ';',
        # This matches either the hostname if it's there, or the instance if it's not.
        # It uses the separator as marker
        'regex'         => '^([^;:]+);.*|^;(.*)',
        'target_label'  => 'instance',
        'replacement'   => '$1',
    }

    prometheus::class_config{ "ceph_server_${::site}":
        dest       => "${targets_path}/ceph_${::site}.yaml",
        class_name => 'role::ceph::server',
        port       => 9283,
    }

    prometheus::class_config{ "matomo_mysql_${::site}":
        dest       => "${targets_path}/mysql_analytics_matomo_${::site}.yaml",
        class_name => 'role::matomo',
        port       => 9104,
    }

    prometheus::class_config{ "analyics_meta_mysql_${::site}":
        dest       => "${targets_path}/mysql_analytics_meta_${::site}.yaml",
        class_name => 'profile::analytics::database::meta',
        port       => 9104,
    }

    # The following jobs are all instances of the statsd_exporter, each running
    # on a host with one (or possibly more than one) airflow instance with monitoring enabled.
    $statsd_airflow_exporter_jobs = [
      {
        'job_name'        => 'airflow_analytics',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => ["${targets_path}/airflow_analytics_${::site}.yaml"] },
        ]
      },
      {
        'job_name'        => 'airflow_analytics_test',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => ["${targets_path}/airflow_analytics_test_${::site}.yaml"] },
        ]
      },
      {
        'job_name'        => 'airflow_analytics_product',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => ["${targets_path}/airflow_analytics_product_${::site}.yaml"] },
        ]
      },
      {
        'job_name'        => 'airflow_platform_eng',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => ["${targets_path}/airflow_platform_eng_${::site}.yaml"] },
        ]
      },
      {
        'job_name'        => 'airflow_research',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => ["${targets_path}/airflow_research_${::site}.yaml"] },
        ]
      },
      {
        'job_name'        => 'airflow_search',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => ["${targets_path}/airflow_search_${::site}.yaml"] },
        ]
      },
      {
        'job_name'        => 'airflow_wmde',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => ["${targets_path}/airflow_wmde_${::site}.yaml"] },
        ]
      },
    ]

    prometheus::class_config { "airflow_analytics_${::site}":
        dest       => "${targets_path}/airflow_analytics_${::site}.yaml",
        class_name => 'role::analytics_cluster::launcher',
        port       => 9112,
    }

    prometheus::class_config { "airflow_analytics_test_${::site}":
        dest       => "${targets_path}/airflow_analytics_test_${::site}.yaml",
        class_name => 'role::analytics_test_cluster::client',
        port       => 9112,
    }

    prometheus::class_config { "airflow_analytics_product_${::site}":
        dest       => "${targets_path}/airflow_analytics_product_${::site}.yaml",
        class_name => 'role::analytics_cluster::airflow::analytics_product',
        port       => 9112,
    }

    prometheus::class_config { "airflow_platform_eng_${::site}":
        dest       => "${targets_path}/airflow_platform_eng_${::site}.yaml",
        class_name => 'role::analytics_cluster::airflow::platform_eng',
        port       => 9112,
    }

    prometheus::class_config { "airflow_research_${::site}":
        dest       => "${targets_path}/airflow_research_${::site}.yaml",
        class_name => 'role::analytics_cluster::airflow::research',
        port       => 9112,
    }

    prometheus::class_config { "airflow_search_${::site}":
        dest       => "${targets_path}/airflow_search_${::site}.yaml",
        class_name => 'role::analytics_cluster::airflow::search',
        port       => 9112,
    }

    prometheus::class_config { "airflow_wmde_${::site}":
        dest       => "${targets_path}/airflow_wmde_${::site}.yaml",
        class_name => 'role::analytics_cluster::airflow::search',
        port       => 9112,
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

    prometheus::jmx_exporter_config{ "zookeeper_analytics_${::site}":
        dest       => "${targets_path}/jmx_zookeeper_analytics_${::site}.yaml",
        class_name => 'role::analytics_cluster::zookeeper',
    }

    prometheus::jmx_exporter_config { "zookeeper_flink_${::site}":
        dest       => "${targets_path}/jmx_zookeeper_flink_${::site}.yaml",
        class_name => 'role::zookeeper::flink',
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

    prometheus::server { 'analytics':
        listen_address       => "127.0.0.1:${port}",
        storage_retention    => $storage_retention,
        global_config_extra  => $config_extra,
        scrape_configs_extra => [$jmx_exporter_jobs, $druid_jobs, $mysql_jobs, $statsd_airflow_exporter_jobs, $ceph_jobs].flatten,
        alertmanagers        => $alertmanagers.map |$a| { "${a}:9093" },
    }

    prometheus::web { 'analytics':
        proxy_pass => "http://localhost:${port}/analytics",
    }

    profile::thanos::sidecar { 'analytics':
        prometheus_port     => $port,
        prometheus_instance => 'analytics',
        enable_upload       => $enable_thanos_upload,
        min_time            => $thanos_min_time,
    }

    prometheus::rule { 'rules_analytics.yml':
        instance => 'analytics',
        source   => 'puppet:///modules/profile/prometheus/rules_analytics.yml',
    }

    prometheus::pint::source { 'analytics':
        port => $port,
    }
}
