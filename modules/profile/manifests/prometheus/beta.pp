class profile::prometheus::beta (
    String $storage_retention = lookup('prometheus::server::storage_retention', {'default_value' => '730h'}),
    Array[Stdlib::Host] $alertmanagers = lookup('alertmanagers', {'default_value' => []}),
){

    $targets_path = '/srv/prometheus/beta/targets'
    $rules_path = '/srv/prometheus/beta/rules'

    # one job per varnish cache 'role'
    $varnish_jobs = [
      {
        'job_name'        => 'varnish-text',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/varnish-text_*.yaml"] },
        ]
      },
      {
        'job_name'        => 'varnish-upload',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/varnish-upload_*.yaml"] },
        ]
      },
    ]

    $mysql_jobs = [
      {
        'job_name'        => 'mysql-core',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/mysql-core_*.yaml"] },
        ]
      },
    ]

    $cassandra_jobs = [
      {
        'job_name'        => 'cassandra-restbase',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/cassandra-restbase_*.yaml"] },
        ]
      },
    ]

    $web_jobs = [
      {
        'job_name'        => 'apache',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/apache_*.yaml"] },
        ]
      },
      {
        'job_name'        => 'memcache',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/memcache_*.yaml"] },
        ]
      },
    ]

    $jmx_exporter_jobs = [
        {
            'job_name'        => 'jmx_kafka',
            'scheme'          => 'http',
            'scrape_timeout'  => '45s',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/jmx_kafka_broker_*.yaml" ]}
            ],
        },
        {
            'job_name'        => 'jmx_kafka_mirrormaker',
            'scheme'          => 'http',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/jmx_kafka_mirrormaker_*.yaml" ]}
            ],
        },
    ]

    # Job definition for memcache_exporter
    $memcached_jobs = [
      {
        'job_name'        => 'memcached',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/memcached_*.yaml"] },
        ]
      },
    ]

    $mcrouter_jobs = [
      {
        'job_name'        => 'mcrouter',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/mcrouter_*.yaml"] },
        ]
      },
    ]
    prometheus::class_config{ "memcached_${::site}":
        dest       => "${targets_path}/memcached_${::site}.yaml",
        class_name => 'profile::prometheus::memcached_exporter',
        port       => 9150,
        labels     => {}
    }

    prometheus::class_config{ "mcrouter_${::site}":
        dest       => "${targets_path}/mcrouter_${::site}.yaml",
        class_name => 'profile::prometheus::mcrouter_exporter',
        port       => 9151,
        labels     => {}
    }

    # Collect all declared kafka_broker_.* jmx_exporter_instances
    # from any uses of profile::kafka::broker::monitoring.
    prometheus::jmx_exporter_config{ "kafka_broker_${::site}":
        dest              => "${targets_path}/jmx_kafka_broker_beta_${::site}.yaml",
        class_name        => 'profile::kafka::broker::monitoring',
        instance_selector => 'kafka_broker_.*',
    }
    # Collect all declared kafka_mirror_.* jmx_exporter_instances
    # from any uses of profile::kafka::mirror.
    prometheus::jmx_exporter_config{ "kafka_mirrormaker_${::site}":
        dest              => "${targets_path}/jmx_kafka_mirrormaker_beta_${::site}.yaml",
        class_name        => 'profile::kafka::mirror',
        instance_selector => 'kafka_mirror_.*',
    }

    prometheus::server { 'beta':
        listen_address       => '127.0.0.1:9903',
        external_url         => 'https://beta-prometheus.wmflabs.org/beta',
        scrape_configs_extra => [
          $varnish_jobs, $mysql_jobs, $web_jobs, $cassandra_jobs,
          $jmx_exporter_jobs, $memcached_jobs, $mcrouter_jobs
        ].flatten,
        storage_retention    => $storage_retention,
        alertmanagers        => $alertmanagers.map |$a| { "${a}:9093" },
    }

    prometheus::web { 'beta':
        proxy_pass => 'http://127.0.0.1:9903/beta',
        homepage   => true,
    }

    prometheus::rule { 'rules_beta.yml':
        instance => 'beta',
        source   => 'puppet:///modules/role/prometheus/rules_beta.yml',
    }

    prometheus::rule { 'alerts_beta.yml':
        instance => 'beta',
        source   => 'puppet:///modules/role/prometheus/alerts_beta.yml',
    }

    $targets_file = "${targets_path}/node_project.yml"

    include ::prometheus::wmcs_scripts

    systemd::timer::job { 'prometheus_labs_project_targets':
        ensure      => 'present',
        description => 'Generate Prometheus targets configuration for a given project from nova API',
        command     => '/usr/local/bin/prometheus-labs-targets.sh',
        user        => 'prometheus',
        interval    => {'start' => 'OnCalendar', 'interval' => '*:0/10:00'},
    }
}
