# Uses the prometheus module and generates the specific configuration
# needed for WMF production
#
# filtertags: labs-project-monitoring
class role::prometheus::ops {
    include ::base::firewall

    $targets_path = '/srv/prometheus/ops/targets'
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


    # Add one job for each of mysql 'group' (i.e. their broad function)
    # Each job will look for new files matching the glob and load the job
    # configuration automatically.
    $mysql_jobs = [
      {
        'job_name'        => 'mysql-core',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/mysql-core_*.yaml"] },
        ]
      },
      {
        'job_name'        => 'mysql-dbstore',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/mysql-dbstore_*.yaml"] },
        ]
      },
      {
        'job_name'        => 'mysql-labs',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/mysql-labs_*.yaml"] },
        ]
      },
      {
        'job_name'        => 'mysql-misc',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/mysql-misc_*.yaml"] },
        ]
      },
      {
        'job_name'        => 'mysql-parsercache',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/mysql-parsercache_*.yaml"] },
        ]
      },
    ]

    # Leave only backend hostname (no VCL UUID) from "varnish_backend" metrics
    # to avoid metric churn on VCL regeneration. See also T150479.
    $varnish_be_uuid_relabel = {
      'source_labels' => ['__name__', 'id'],
      'regex'         => 'varnish_backend_.+;root:[-a-f0-9]+\.(.*)',
      'target_label'  => 'id',
    }

    # one job per varnish cache 'role'
    $varnish_jobs = [
      {
        'job_name'        => 'varnish-text',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/varnish-text_*.yaml"] },
        ],
        'metric_relabel_configs' => [$varnish_be_uuid_relabel],
      },
      {
        'job_name'        => 'varnish-upload',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/varnish-upload_*.yaml"] },
        ],
        'metric_relabel_configs' => [$varnish_be_uuid_relabel],
      },
      {
        'job_name'        => 'varnish-maps',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/varnish-maps_*.yaml"] },
        ],
        'metric_relabel_configs' => [$varnish_be_uuid_relabel],
      },
      {
        'job_name'        => 'varnish-misc',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/varnish-misc_*.yaml"] },
        ],
        'metric_relabel_configs' => [$varnish_be_uuid_relabel],
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

    # Generate a list of hosts running memcached from Ganglia cluster definition
    prometheus::cluster_config{ "memcached_${::site}":
        dest    => "${targets_path}/memcached_${::site}.yaml",
        site    => $::site,
        cluster => 'memcached',
        port    => '9150',
        labels  => {}
    }

    # Job definition for hhvm_exporter
    $hhvm_jobs = [
      {
        'job_name'        => 'hhvm',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/hhvm_*.yaml"] },
        ]
      },
    ]

    # Generate a list of hosts running hhvm from Ganglia cluster definition
    # TODO: generate the configuration based on hosts with hhvm class applied
    prometheus::cluster_config{ "hhvm_jobrunner_${::site}":
        dest    => "${targets_path}/hhvm_jobrunner_${::site}.yaml",
        site    => $::site,
        cluster => 'jobrunner',
        port    => '9192',
        labels  => {
            'cluster' => 'jobrunner'
        }
    }
    prometheus::cluster_config{ "hhvm_appserver_${::site}":
        dest    => "${targets_path}/hhvm_appserver_${::site}.yaml",
        site    => $::site,
        cluster => 'appserver',
        port    => '9192',
        labels  => {
            'cluster' => 'appserver'
        }
    }
    prometheus::cluster_config{ "hhvm_api_appserver_${::site}":
        dest    => "${targets_path}/hhvm_api_appserver_${::site}.yaml",
        site    => $::site,
        cluster => 'api_appserver',
        port    => '9192',
        labels  => {
            'cluster' => 'api_appserver'
        }
    }
    prometheus::cluster_config{ "hhvm_imagescaler_${::site}":
        dest    => "${targets_path}/hhvm_imagescaler_${::site}.yaml",
        site    => $::site,
        cluster => 'imagescaler',
        port    => '9192',
        labels  => {
            'cluster' => 'imagescaler'
        }
    }

    prometheus::cluster_config{ "hhvm_videoscaler_${::site}":
        dest    => "${targets_path}/hhvm_videoscaler_${::site}.yaml",
        site    => $::site,
        cluster => 'videoscaler',
        port    => '9192',
        labels  => {
            'cluster' => 'videoscaler'
        }
    }

    # Job definition for apache_exporter
    $apache_jobs = [
      {
        'job_name'        => 'apache',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/apache_*.yaml"] },
        ]
      },
    ]

    # Generate a list of hosts running apache from Ganglia cluster definition
    # TODO(filippo): generate the configuration based on hosts with apache class applied
    prometheus::cluster_config{ "apache_jobrunner_${::site}":
        dest    => "${targets_path}/apache_jobrunner_${::site}.yaml",
        site    => $::site,
        cluster => 'jobrunner',
        port    => '9117',
        labels  => {
            'cluster' => 'jobrunner'
        }
    }
    prometheus::cluster_config{ "apache_appserver_${::site}":
        dest    => "${targets_path}/apache_appserver_${::site}.yaml",
        site    => $::site,
        cluster => 'appserver',
        port    => '9117',
        labels  => {
            'cluster' => 'appserver'
        }
    }
    prometheus::cluster_config{ "apache_api_appserver_${::site}":
        dest    => "${targets_path}/apache_api_appserver_${::site}.yaml",
        site    => $::site,
        cluster => 'api_appserver',
        port    => '9117',
        labels  => {
            'cluster' => 'api_appserver'
        }
    }
    prometheus::cluster_config{ "apache_imagescaler_${::site}":
        dest    => "${targets_path}/apache_imagescaler_${::site}.yaml",
        site    => $::site,
        cluster => 'imagescaler',
        port    => '9117',
        labels  => {
            'cluster' => 'imagescaler'
        }
    }
    prometheus::cluster_config{ "apache_videoscaler_${::site}":
        dest    => "${targets_path}/apache_videoscaler_${::site}.yaml",
        site    => $::site,
        cluster => 'videoscaler',
        port    => '9117',
        labels  => {
            'cluster' => 'videoscaler'
        }
    }
    # Job definition for etcd_exporter
    $etcd_jobs = [
      {
        'job_name'        => 'etcd',
        'scheme'          => 'https',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/etcd_*.yaml" ]}
        ],
      },
    ]

    $etcdmirror_jobs = [
      {
        'job_name'        => 'etcdmirror',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/etcdmirror_*.yaml" ]}
        ],
      },
    ]

    # Gather etcd metrics from machines exposing them via http
    prometheus::class_config{ "etcd_servers_${::site}":
        dest       => "${targets_path}/etcd_${::site}.yaml",
        site       => $::site,
        class_name => 'profile::etcd::tlsproxy',
        port       => 2379,
    }

    # Gather replication stats where etcd-mirror is running.
    prometheus::class_config{ "etcdmirror_${::site}":
        dest             => "${targets_path}/etcdmirror_${::site}.yaml",
        site             => $::site,
        class_name       => 'profile::etcd::replication',
        class_parameters => {
            'active' => true
        },
        port             => 8000,
    }

    $pdu_jobs = [
      {
        'job_name'        => 'pdu',
        'metrics_path'    => '/snmp',
        'params'          => {
          'module' => [ "pdu_${::site}" ],
        },
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/pdu_*.yaml" ] }
        ],
        'relabel_configs' => [
          { 'source_labels' => ['__address__'],
            'target_label'  => '__param_target',
          },
          { 'source_labels' => ['__param_target'],
            'target_label'  => 'instance',
          },
          { 'target_label' => ['__address__'],
            'replacement'  => 'netmon1001.wikimedia.org:9116',
          },
        ],
      },
    ]

    prometheus::class_config { "pdu_${::site}":
        dest       => "${targets_path}/pdu_${::site}.yaml",
        site       => $::site,
        class_name => 'facilities::monitor_pdu_3phase',
        port       => '',
    }

    prometheus::server { 'ops':
        storage_encoding      => '2',
        listen_address        => '127.0.0.1:9900',
        storage_retention     => $storage_retention,
        max_chunks_to_persist => $max_chunks_to_persist,
        memory_chunks         => $memory_chunks,
        scrape_configs_extra  => array_concat(
            $mysql_jobs, $varnish_jobs, $memcached_jobs, $hhvm_jobs,
            $apache_jobs, $etcd_jobs, $etcdmirror_jobs, $pdu_jobs
        ),
        global_config_extra   => $config_extra,
    }

    prometheus::web { 'ops':
        proxy_pass => 'http://localhost:9900/ops',
    }

    ferm::service { 'prometheus-web':
        proto  => 'tcp',
        port   => '80',
        srange => '$DOMAIN_NETWORKS',
    }

    File {
        backup  => false,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    # Query puppet exported resources and generate a list of hosts for
    # prometheus to poll metrics from. Ganglia::Cluster is used to generate the
    # mapping from cluster to a list of its members.
    $content = $::use_puppetdb ? {
        true => template('role/prometheus/node_site.yaml.erb'),
        default => generate('/usr/local/bin/prometheus-ganglia-gen',
        "--site=${::site}"),
    }
    file { "${targets_path}/node_site_${::site}.yaml":
        content => $content,
    }

    # Generate static placeholders for mysql jobs
    # this is only a temporary measure until we generate them from
    # a template and some exported resources
    file { "${targets_path}/mysql-core_${::site}.yaml":
        source => "puppet:///modules/role/prometheus/mysql-core_${::site}.yaml",
    }
    file { "${targets_path}/mysql-dbstore_${::site}.yaml":
        source => "puppet:///modules/role/prometheus/mysql-dbstore_${::site}.yaml",
    }
    file { "${targets_path}/mysql-misc_${::site}.yaml":
        source => "puppet:///modules/role/prometheus/mysql-misc_${::site}.yaml",
    }
    file { "${targets_path}/mysql-parsercache_${::site}.yaml":
        source => "puppet:///modules/role/prometheus/mysql-parsercache_${::site}.yaml",
    }
    file { "${targets_path}/mysql-labs_${::site}.yaml":
        source => "puppet:///modules/role/prometheus/mysql-labs_${::site}.yaml",
    }

    prometheus::rule { 'rules_ops.conf':
        instance => 'ops',
        source   => 'puppet:///modules/role/prometheus/rules_ops.conf',
    }

    prometheus::varnish_2layer{ 'maps':
        targets_path => $targets_path,
        cache_name   => 'maps',
    }

    prometheus::varnish_2layer{ 'misc':
        targets_path => $targets_path,
        cache_name   => 'misc',
    }

    prometheus::varnish_2layer{ 'text':
        targets_path => $targets_path,
        cache_name   => 'text',
    }

    prometheus::varnish_2layer{ 'upload':
        targets_path => $targets_path,
        cache_name   => 'upload',
    }

    # Move Prometheus metrics to new HW - T148408
    include rsync::server

    $prometheus_nodes_ferm = join(hiera('prometheus_nodes'), ' ')

    rsync::server::module { 'prometheus-ops':
        path        => '/srv/prometheus/ops/metrics',
        uid         => 'prometheus',
        gid         => 'prometheus',
        hosts_allow => $prometheus_nodes_ferm,
    }

    ferm::service { 'rsync-prometheus':
        proto  => 'tcp',
        port   => '873',
        srange => "(@resolve((${prometheus_nodes_ferm})) @resolve((${prometheus_nodes_ferm}), AAAA))",
    }
}
