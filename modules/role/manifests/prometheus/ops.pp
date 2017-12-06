# Uses the prometheus module and generates the specific configuration
# needed for WMF production
#
# filtertags: labs-project-monitoring
class role::prometheus::ops {
    system::role { 'prometheus::ops':
        description => 'Prometheus server (ops)',
    }

    include ::standard
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

    include ::prometheus::blackbox_exporter
    $blackbox_jobs = [
      {
        'job_name'        => 'blackbox_icmp',
        'metrics_path'    => '/probe',
        'params'          => {
          'module' => [ 'icmp' ],
        },
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/blackbox_icmp_*.yaml" ] }
        ],
        'relabel_configs' => [
          { 'source_labels' => ['__address__'],
            'target_label'  => '__param_target',
          },
          { 'source_labels' => ['__param_target'],
            'target_label'  => 'instance',
          },
          { 'target_label' => '__address__',
            'replacement'  => '127.0.0.1:9115',
          },
        ],
      },
      {
        'job_name'        => 'blackbox_ssh',
        'metrics_path'    => '/probe',
        'params'          => {
          'module' => [ 'ssh_banner' ],
        },
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/blackbox_ssh_*.yaml" ] }
        ],
        'relabel_configs' => [
          { 'source_labels' => ['__address__'],
            'target_label'  => '__param_target',
          },
          { 'source_labels' => ['__param_target'],
            'target_label'  => 'instance',
          },
          { 'target_label' => '__address__',
            'replacement'  => '127.0.0.1:9115',
          },
        ],
      },
      {
        'job_name'        => 'blackbox_tcp',
        'metrics_path'    => '/probe',
        'params'          => {
          'module' => [ 'tcp_connect' ],
        },
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/blackbox_tcp_*.yaml" ] }
        ],
        'relabel_configs' => [
          { 'source_labels' => ['__address__'],
            'target_label'  => '__param_target',
          },
          { 'source_labels' => ['__param_target'],
            'target_label'  => 'instance',
          },
          { 'target_label' => '__address__',
            'replacement'  => '127.0.0.1:9115',
          },
        ],
      },
      {
        'job_name'        => 'blackbox_http',
        'metrics_path'    => '/probe',
        'params'          => {
          'module' => [ 'http_connect' ],
        },
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/blackbox_http_*.yaml" ] }
        ],
        'relabel_configs' => [
          { 'source_labels' => ['__address__'],
            'target_label'  => '__param_target',
          },
          { 'source_labels' => ['__param_target'],
            'target_label'  => 'instance',
          },
          { 'target_label' => '__address__',
            'replacement'  => '127.0.0.1:9115',
          },
        ],
      },
      {
        'job_name'        => 'blackbox_https',
        'metrics_path'    => '/probe',
        'params'          => {
          'module' => [ 'https_connect' ],
        },
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/blackbox_https_*.yaml" ] }
        ],
        'relabel_configs' => [
          { 'source_labels' => ['__address__'],
            'target_label'  => '__param_target',
          },
          { 'source_labels' => ['__param_target'],
            'target_label'  => 'instance',
          },
          { 'target_label' => '__address__',
            'replacement'  => '127.0.0.1:9115',
          },
        ],
      },
    ]

    # Ping and SSH probes for all bastions from all machines running
    # prometheus::ops
    file { "${targets_path}/blackbox_icmp_bastions.yaml":
      content => ordered_yaml([{'targets' => $::network::constants::special_hosts[$::realm]['bastion_hosts']}]),
    }
    file { "${targets_path}/blackbox_ssh_bastions.yaml":
      content => ordered_yaml([{
        'targets' => regsubst($::network::constants::special_hosts[$::realm]['bastion_hosts'], '(.*)', '[\0]:22')
        }]),
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
        'job_name'        => 'varnish-misc',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/varnish-misc_*.yaml"] },
        ],
        'metric_relabel_configs' => [$varnish_be_uuid_relabel],
      },
      {
        'job_name'        => 'varnish-canary',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/varnish-canary_*.yaml"] },
        ],
        'metric_relabel_configs' => [$varnish_be_uuid_relabel],
      },
    ]

    # Pull varnish-related metrics generated via mtail
    prometheus::class_config{ "varnish-canary_mtail_${::site}":
        dest       => "${targets_path}/varnish-canary_mtail_${::site}.yaml",
        site       => $::site,
        class_name => 'role::cache::canary',
        port       => '3903',
    }
    prometheus::class_config{ "varnish-misc_mtail_${::site}":
        dest       => "${targets_path}/varnish-misc_mtail_${::site}.yaml",
        site       => $::site,
        class_name => 'role::cache::misc',
        port       => '3903',
    }

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

    # Special config for Apache on Piwik deployments
    prometheus::class_config{ "apache_piwik_${::site}":
        dest       => "${targets_path}/apache_piwik_${::site}.yaml",
        site       => $::site,
        class_name => 'profile::piwik::webserver',
        port       => '9117',
    }

    # Special config for Apache on OTRS deployment
    prometheus::class_config{ "apache_otrs_${::site}":
        dest       => "${targets_path}/apache_otrs_${::site}.yaml",
        site       => $::site,
        class_name => 'profile::otrs',
        port       => '9117',
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
          { 'target_label' => '__address__',
            'replacement'  => 'netmon1002.wikimedia.org:9116',
          },
        ],
      },
    ]

    prometheus::pdu_config { "pdu_${::site}":
        dest => "${targets_path}/pdu_${::site}.yaml",
        site => $::site,
    }

    $ircd_jobs = [
      {
        'job_name'        => 'ircd',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/ircd_*.yaml" ]}
        ],
      },
    ]

    prometheus::class_config{ "ircd_${::site}":
        dest       => "${targets_path}/ircd_${::site}.yaml",
        site       => $::site,
        class_name => 'role::mw_rc_irc',
        port       => '9197',
    }

    # Job definition for nginx exporter
    $nginx_jobs = [
      {
        'job_name'        => 'nginx',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/nginx_*.yaml" ]}
        ],
      },
    ]

    prometheus::cluster_config{ "nginx_cache_misc_${::site}":
        dest    => "${targets_path}/nginx_cache_misc_${::site}.yaml",
        site    => $::site,
        cluster => 'cache_misc',
        port    => 9145,
        labels  => {
            'cluster' => 'cache_misc'
        },
    }

    prometheus::cluster_config{ "nginx_cache_text_${::site}":
        dest    => "${targets_path}/nginx_cache_text_${::site}.yaml",
        site    => $::site,
        cluster => 'cache_text',
        port    => 9145,
        labels  => {
            'cluster' => 'cache_text'
        },
    }

    prometheus::cluster_config{ "nginx_cache_upload_${::site}":
        dest    => "${targets_path}/nginx_cache_upload_${::site}.yaml",
        site    => $::site,
        cluster => 'cache_upload',
        port    => 9145,
        labels  => {
            'cluster' => 'cache_upload'
        },
    }

    prometheus::cluster_config{ "nginx_thumbor_${::site}":
        dest    => "${targets_path}/nginx_thumbor_${::site}.yaml",
        site    => $::site,
        cluster => 'thumbor',
        port    => 8800,
        labels  => {
            'cluster' => 'thumbor'
        },
    }

    # Job definition for pybal
    $pybal_jobs = [
      {
        'job_name'        => 'pybal',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/pybal_*.yaml" ]}
        ],
      },
    ]

    prometheus::class_config{ "pybal_${::site}":
        dest       => "${targets_path}/pybal_${::site}.yaml",
        class_name => 'role::lvs::balancer',
        site       => $::site,
        port       => 9090,
    }

    $jmx_exporter_jobs = [
      {
        'job_name'        => 'jmx_kafka',
        'scrape_timeout'  => '25s',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/jmx_kafka_*.yaml" ]}
        ],
      },
    ]

    prometheus::jmx_exporter_config{ "kafka_broker_jumbo_${::site}":
        dest       => "${targets_path}/jmx_kafka_broker_jumbo_${::site}.yaml",
        class_name => 'role::kafka::jumbo::broker',
        site       => $::site,
    }


    # redis_exporter runs alongside each redis instance, thus drop the (uninteresting in this
    # case) 'addr' and 'alias' labels
    $redis_exporter_relabel = {
      'regex'  => '(addr|alias)',
      'action' => 'labeldrop',
    }

    # Configure one job per redis multidc 'category', plus redis for maps.
    $redis_jobs = [
      {
        'job_name'        => 'redis_sessions',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/redis_sessions_*.yaml" ]}
        ],
        'metric_relabel_configs' => [ $redis_exporter_relabel ],
      },
      {
        'job_name'        => 'redis_jobqueue',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/redis_jobqueue_*.yaml" ]}
        ],
        'metric_relabel_configs' => [ $redis_exporter_relabel ],
      },
      {
        'job_name'        => 'redis_maps',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/redis_maps_*.yaml" ]}
        ],
        'metric_relabel_configs' => [ $redis_exporter_relabel ],
      },
      {
        'job_name'        => 'redis_ores',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/redis_ores_*.yaml" ]}
        ],
        'metric_relabel_configs' => [ $redis_exporter_relabel ],
      },
    ]

    prometheus::redis_exporter_config{ "redis_sessions_${::site}":
        dest       => "${targets_path}/redis_sessions_${::site}.yaml",
        class_name => 'role::mediawiki::memcached',
        site       => $::site,
    }

    prometheus::redis_exporter_config{ "redis_jobqueue_master_${::site}":
        dest       => "${targets_path}/redis_jobqueue_master_${::site}.yaml",
        class_name => 'role::jobqueue_redis::master',
        site       => $::site,
    }

    prometheus::redis_exporter_config{ "redis_jobqueue_slave_${::site}":
        dest       => "${targets_path}/redis_jobqueue_slave_${::site}.yaml",
        class_name => 'role::jobqueue_redis::slave',
        site       => $::site,
    }

    prometheus::redis_exporter_config{ "redis_maps_${::site}":
        dest       => "${targets_path}/redis_maps_${::site}.yaml",
        class_name => 'role::maps::master',
        site       => $::site,
    }

    prometheus::redis_exporter_config{ "redis_ores_${::site}":
        dest       => "${targets_path}/redis_ores_${::site}.yaml",
        class_name => 'role::ores::redis',
        site       => $::site,
    }

    $mtail_jobs = [
      {
        'job_name'        => 'mtail',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/mtail_*.yaml" ]}
        ],
      },
    ]

    prometheus::class_config{ "mtail_mx_${::site}":
        dest       => "${targets_path}/mtail_mx_${::site}.yaml",
        site       => $::site,
        class_name => 'role::mail::mx',
        port       => '3903',
    }

    prometheus::class_config{ "mtail_syslog_${::site}":
        dest       => "${targets_path}/mtail_syslog_${::site}.yaml",
        site       => $::site,
        class_name => 'role::syslog::centralserver',
        port       => '3903',
    }

    $ldap_jobs = [
      {
        'job_name'        => 'ldap',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/ldap_*.yaml" ]}
        ],
      },
    ]

    prometheus::class_config{ "ldap_${::site}":
        dest       => "${targets_path}/ldap_${::site}.yaml",
        site       => $::site,
        class_name => 'role::openldap::labs',
        port       => '9142',
    }

    prometheus::server { 'ops':
        storage_encoding      => '2',
        listen_address        => '127.0.0.1:9900',
        storage_retention     => $storage_retention,
        max_chunks_to_persist => $max_chunks_to_persist,
        memory_chunks         => $memory_chunks,
        scrape_configs_extra  => array_concat(
            $mysql_jobs, $varnish_jobs, $memcached_jobs, $hhvm_jobs,
            $apache_jobs, $etcd_jobs, $etcdmirror_jobs, $pdu_jobs,
            $nginx_jobs, $pybal_jobs, $blackbox_jobs, $jmx_exporter_jobs,
            $redis_jobs, $mtail_jobs, $ldap_jobs, $ircd_jobs,
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

    prometheus::varnish_2layer{ 'canary':
        targets_path => $targets_path,
        cache_name   => 'canary',
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
