# Uses the prometheus module and generates the specific configuration
# needed for WMF production
#
# filtertags: labs-project-monitoring
class profile::prometheus::ops (
    $prometheus_nodes_ = hiera('prometheus_nodes'),
    $storage_retention = hiera('prometheus::server::storage_retention', '2190h'),
    $max_chunks_to_persist = hiera('prometheus::server::max_chunks_to_persist', '524288'),
    $memory_chunks = hiera('prometheus::server::memory_chunks', '1048576'),
    $targets_path = lookup('prometheus::server::target_path', String, 'first', '/srv/prometheus/ops/targets'),
    $bastion_hosts = hiera('bastion_hosts', []),
){

    include ::passwords::gerrit
    $gerrit_client_token = $passwords::gerrit::prometheus_bearer_token

    $config_extra = {
        # All metrics will get an additional 'site' label when queried by
        # external systems (e.g. via federation)
        'external_labels' => {
            'site' => $::site,
        },
    }

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
      content => ordered_yaml([{'targets' => $bastion_hosts}]),
    }
    file { "${targets_path}/blackbox_ssh_bastions.yaml":
      content => ordered_yaml([{
        'targets' => regsubst($bastion_hosts, '(.*)', '[\0]:22')
        }]),
    }

    $gerrit_jobs = [
      {
          'job_name'          => 'gerrit',
          'bearer_token_file' => '/srv/prometheus/ops/gerrit.token',
          'metrics_path'      => '/r/monitoring',
          'params'            => { 'format' => ['prometheus'] },
          'scheme'            => 'https',
          'file_sd_configs' => [
              { 'files' => [ "${targets_path}/gerrit.yaml" ] }
          ],
          'tls_config'        => {
              'server_name'   => 'gerrit.wikimedia.org',
          },
      },
    ]

    $gerrit_targets = {
      'targets' => ['gerrit.wikimedia.org:443'],
      'labels'  => {'cluster' => 'misc', 'site' => 'eqiad'},
    }
    file { "${targets_path}/gerrit.yaml":
      content => ordered_yaml([$gerrit_targets]),
    }

    # Add one job for each of mysql 'group' (i.e. their broad function)
    # Each job will look for new files matching the glob and load the job
    # configuration automatically.
    # REMEMBER to change mysqld_exporter_config.py if you change these
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
          { 'files' => ["${targets_path}/varnish-upload_*.yaml"] },
        ],
        'metric_relabel_configs' => [$varnish_be_uuid_relabel],
      },
      {
        'job_name'        => 'trafficserver-upload',
        'file_sd_configs' => [
          { 'files' => ["${targets_path}/trafficserver-upload_*.yaml"] },
        ],
      },
      {
        'job_name'        => 'varnish-canary',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/varnish-canary_*.yaml"] },
        ],
        'metric_relabel_configs' => [$varnish_be_uuid_relabel],
      },
    ]

    # Pull varnish-related metrics generated via mtail (frontend)
    prometheus::class_config{ "varnish-canary_mtail_${::site}":
        dest       => "${targets_path}/varnish-canary_mtail_${::site}.yaml",
        site       => $::site,
        class_name => 'role::cache::canary',
        port       => 3903,
    }
    prometheus::class_config{ "varnish-upload_mtail_${::site}":
        dest       => "${targets_path}/varnish-upload_mtail_${::site}.yaml",
        site       => $::site,
        class_name => 'role::cache::upload',
        port       => 3903,
    }
    prometheus::class_config{ "varnish-text_mtail_${::site}":
        dest       => "${targets_path}/varnish-text_mtail_${::site}.yaml",
        site       => $::site,
        class_name => 'role::cache::text',
        port       => 3903,
    }

    # And varnish backend instance stats generated by mtail
    prometheus::class_config{ "varnish-canary_backendmtail_${::site}":
        dest       => "${targets_path}/varnish-canary_backendmtail_${::site}.yaml",
        site       => $::site,
        class_name => 'role::cache::canary',
        port       => 3904,
    }
    prometheus::class_config{ "varnish-text_backendmtail_${::site}":
        dest       => "${targets_path}/varnish-text_backendmtail_${::site}.yaml",
        site       => $::site,
        class_name => 'role::cache::text',
        port       => 3904,
    }

    # ATS origin server stats generated by mtail
    prometheus::class_config{ "trafficserver-upload_backendmtail_${::site}":
        dest       => "${targets_path}/trafficserver-upload_backendmtail_${::site}.yaml",
        site       => $::site,
        class_name => 'role::cache::upload',
        port       => 3904,
    }

    # Job definition for trafficserver_exporter
    $trafficserver_jobs = [
      {
        'job_name'        => 'trafficserver',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/trafficserver_*.yaml"] },
        ],
      },
    ]

    prometheus::class_config{ "trafficserver_${::site}":
        dest       => "${targets_path}/trafficserver_${::site}.yaml",
        site       => $::site,
        class_name => 'profile::trafficserver::backend',
        port       => 9122,
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

    # Generate a list of hosts running memcached from wikimedia_clusters definition in Hiera
    prometheus::class_config{ "memcached_${::site}":
        dest       => "${targets_path}/memcached_${::site}.yaml",
        site       => $::site,
        class_name => 'profile::prometheus::memcached_exporter',
        port       => 9150,
        labels     => {}
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

    # Generate a list of hosts running hhvm from wikimedia_clusters definition in Hiera
    # TODO: generate the configuration based on hosts with hhvm class applied
    prometheus::cluster_config{ "hhvm_jobrunner_${::site}":
        dest    => "${targets_path}/hhvm_jobrunner_${::site}.yaml",
        site    => $::site,
        cluster => 'jobrunner',
        port    => 9192,
        labels  => {
            'cluster' => 'jobrunner'
        }
    }
    prometheus::cluster_config{ "hhvm_appserver_${::site}":
        dest    => "${targets_path}/hhvm_appserver_${::site}.yaml",
        site    => $::site,
        cluster => 'appserver',
        port    => 9192,
        labels  => {
            'cluster' => 'appserver'
        }
    }
    prometheus::cluster_config{ "hhvm_api_appserver_${::site}":
        dest    => "${targets_path}/hhvm_api_appserver_${::site}.yaml",
        site    => $::site,
        cluster => 'api_appserver',
        port    => 9192,
        labels  => {
            'cluster' => 'api_appserver'
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

    # Generate a list of hosts running apache from wikimedia_clusters definition in Hiera
    # TODO(filippo): generate the configuration based on hosts with apache class applied
    prometheus::cluster_config{ "apache_jobrunner_${::site}":
        dest    => "${targets_path}/apache_jobrunner_${::site}.yaml",
        site    => $::site,
        cluster => 'jobrunner',
        port    => 9117,
        labels  => {
            'cluster' => 'jobrunner'
        }
    }
    prometheus::cluster_config{ "apache_appserver_${::site}":
        dest    => "${targets_path}/apache_appserver_${::site}.yaml",
        site    => $::site,
        cluster => 'appserver',
        port    => 9117,
        labels  => {
            'cluster' => 'appserver'
        }
    }
    prometheus::cluster_config{ "apache_api_appserver_${::site}":
        dest    => "${targets_path}/apache_api_appserver_${::site}.yaml",
        site    => $::site,
        cluster => 'api_appserver',
        port    => 9117,
        labels  => {
            'cluster' => 'api_appserver'
        }
    }

    # Special config for Apache on Piwik deployments
    prometheus::class_config{ "apache_piwik_${::site}":
        dest       => "${targets_path}/apache_piwik_${::site}.yaml",
        site       => $::site,
        class_name => 'profile::piwik::webserver',
        port       => 9117,
    }

    # Special config for Apache on OTRS deployment
    prometheus::class_config{ "apache_otrs_${::site}":
        dest       => "${targets_path}/apache_otrs_${::site}.yaml",
        site       => $::site,
        class_name => 'profile::otrs',
        port       => 9117,
    }

    # Special config for Apache on Phabricator deployment
    prometheus::class_config{ "apache_phabricator_${::site}":
        dest       => "${targets_path}/apache_phabricator_${::site}.yaml",
        site       => $::site,
        class_name => 'profile::phabricator::main',
        port       => 9117,
    }

    # Job definition for icinga_exporter
    $icinga_jobs = [
      {
        'job_name'        => 'icinga',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/icinga_*.yaml" ]}
        ],
      },
    ]

    # Special config for Icinga exporter
    prometheus::class_config{ "icinga_${::site}":
        dest       => "${targets_path}/icinga_${::site}.yaml",
        site       => $::site,
        class_name => 'profile::icinga',
        port       => 9245,
    }

    # Job definition for varnishkafka exporter
    $varnishkafka_jobs = [
      {
        'job_name'        => 'varnishkafka',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/varnishkafka_*.yaml" ]}
        ],
      }
    ]

    # Special config for varnishkafka exporter
    prometheus::class_config{ "varnishkafka_${::site}":
        dest       => "${targets_path}/varnishkafka_${::site}.yaml",
        site       => $::site,
        class_name => 'profile::prometheus::varnishkafka_exporter',
        port       => 9132,
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

    # mcrouter
    # Job definition for mcrouter_exporter
    $mcrouter_jobs = [
      {
        'job_name'        => 'mcrouter',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/mcrouter_*.yaml" ]}
        ],
      },
    ]
    prometheus::class_config{ "mcrouter_${::site}":
        dest       => "${targets_path}/mcrouter_${::site}.yaml",
        site       => $::site,
        class_name => 'profile::prometheus::mcrouter_exporter',
        port       => 9151,
    }

    # php and php-fpm
    $php_jobs =  [
        {
        'job_name'        => 'php',
        'scheme'          => 'http',
        'file_sd_configs' => [
            { 'files' => [ "${targets_path}/php_*.yaml" ]}
        ],
        },
    ]

    $php_fpm_jobs = [
        {
        'job_name'        => 'php-fpm',
        'scheme'          => 'http',
        'file_sd_configs' => [
            { 'files' => [ "${targets_path}/php-fpm_*.yaml" ]}
        ],
        },
    ]
    prometheus::class_config{ "php_${::site}":
        dest       => "${targets_path}/php_${::site}.yaml",
        site       => $::site,
        class_name => 'profile::mediawiki::php::monitoring',
        port       => 9181,
    }
    prometheus::class_config{ "php-fpm_${::site}":
        dest       => "${targets_path}/php-fpm_${::site}.yaml",
        site       => $::site,
        class_name => 'profile::prometheus::php_fpm_exporter',
        port       => 9180,
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

    # T221099
    $docker_registry_jobs = [
      {
        'job_name'        => 'docker-registry',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/docker_registry_*.yaml" ]}
        ],
      },
    ]

    prometheus::class_config{ "docker_registry_${::site}":
        dest       => "${targets_path}/docker_registry_${::site}.yaml",
        site       => $::site,
        class_name => 'profile::docker_registry_ha::registry',
        port       => 5001,
    }

    $routinator_jobs = [
      {
        'job_name'        => 'routinator',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/routinator_*.yaml" ]}
        ],
      },
    ]

    prometheus::class_config{ "routinator_${::site}":
        dest       => "${targets_path}/routinator_${::site}.yaml",
        site       => $::site,
        class_name => 'role::rpkivalidator',
        port       => 9556,
    }

    $rpkicounter_jobs = [
      {
        'job_name'        => 'rpkicounter',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/rpkicounter_*.yaml" ]}
        ],
      },
    ]

    prometheus::class_config{ "rpkicounter_${::site}":
        dest       => "${targets_path}/rpkicounter_${::site}.yaml",
        site       => $::site,
        class_name => 'role::netinsights',
        port       => 9200,
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
        port       => 9197,
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
        'job_name'        => 'jmx_logstash',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/jmx_logstash_*.yaml" ]}
        ],
      },
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
      {
        'job_name'        => 'jmx_puppetdb',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/jmx_puppetdb_*.yaml" ]}
        ],
      },
      {
        'job_name'        => 'jmx_wdqs_blazegraph',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/jmx_wdqs_blazegraph_*.yaml" ]}
        ],
      },
      {
        'job_name'        => 'jmx_wdqs_updater',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/jmx_wdqs_updater_*.yaml" ]}
        ],
      },
      {
        'job_name'        => 'jmx_zookeeper',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/jmx_zookeeper_*.yaml" ]}
        ],
      },
    ]

    prometheus::jmx_exporter_config{ "logstash_${::site}":
        dest       => "${targets_path}/jmx_logstash_${::site}.yaml",
        class_name => 'role::logstash',
        site       => $::site,
    }

    # Collect all declared kafka_broker_.* jmx_exporter_instances
    # from any uses of profile::kafka::broker::monitoring.
    prometheus::jmx_exporter_config{ "kafka_broker_${::site}":
        dest              => "${targets_path}/jmx_kafka_broker_${::site}.yaml",
        class_name        => 'profile::kafka::broker::monitoring',
        instance_selector => 'kafka_broker_.*',
        site              => $::site,
    }
    # Collect all declared kafka_mirror_.* jmx_exporter_instances
    # from any uses of profile::kafka::mirror.
    prometheus::jmx_exporter_config{ "kafka_mirrormaker_${::site}":
        dest              => "${targets_path}/jmx_kafka_mirrormaker_${::site}.yaml",
        class_name        => 'profile::kafka::mirror',
        instance_selector => 'kafka_mirror_.*',
        site              => $::site,
    }


    prometheus::jmx_exporter_config{ "puppetdb_${::site}":
        dest       => "${targets_path}/jmx_puppetdb_${::site}.yaml",
        class_name => 'role::puppetmaster::puppetdb',
        site       => $::site,
    }

    prometheus::jmx_exporter_config{ "wdqs_blazegraph_${::site}":
        dest              => "${targets_path}/jmx_wdqs_blazegraph_${::site}.yaml",
        class_name        => 'profile::wdqs::blazegraph',
        instance_selector => 'wdqs_blazegraph',
        site              => $::site,
    }
    prometheus::jmx_exporter_config { "wdqs_updater_${::site}":
        dest              => "${targets_path}/jmx_wdqs_updater_${::site}.yaml",
        class_name        => 'profile::wdqs::updater',
        instance_selector => 'wdqs_updater',
        site              => $::site,
    }

    prometheus::jmx_exporter_config{ "zookeeper_${::site}_old":
        dest       => "${targets_path}/jmx_zookeeper_${::site}_old.yaml",
        class_name => 'role::configcluster',
        site       => $::site,
        labels     => {
            'cluster' => "main-${::site}",
        },
    }

    prometheus::jmx_exporter_config{ "zookeeper_${::site}":
        dest       => "${targets_path}/jmx_zookeeper_${::site}.yaml",
        class_name => 'role::configcluster_stretch',
        site       => $::site,
        labels     => {
            'cluster' => "main-${::site}",
        },
    }

    $etherpad_jobs = [
      {
        'job_name'        => 'etherpad',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/etherpad_*.yaml" ]}
        ],
      },
    ]

    prometheus::class_config{ "etherpad_${::site}":
        dest       => "${targets_path}/etherpad_${::site}.yaml",
        site       => $::site,
        class_name => 'role::etherpad',
        port       => 9198,
    }

    $blazegraph_jobs = [
      {
        'job_name'        => 'blazegraph',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/blazegraph_*.yaml" ]}
        ],
      },
    ]

    prometheus::resource_config{ "blazegraph_${::site}":
        dest           => "${targets_path}/blazegraph_${::site}.yaml",
        site           => $::site,
        define_name    => 'prometheus::blazegraph_exporter',
        port_parameter => 'prometheus_port'
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
        'job_name'        => 'redis_misc',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/redis_misc_*.yaml" ]}
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

    prometheus::redis_exporter_config{ "redis_misc_master_${::site}":
        dest       => "${targets_path}/redis_misc_master_${::site}.yaml",
        class_name => 'role::redis::misc::master',
        site       => $::site,
    }

    prometheus::redis_exporter_config{ "redis_misc_slave_${::site}":
        dest       => "${targets_path}/redis_misc_slave_${::site}.yaml",
        class_name => 'role::redis::misc::slave',
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
        port       => 3903,
    }

    prometheus::class_config{ "mtail_syslog_${::site}":
        dest       => "${targets_path}/mtail_syslog_${::site}.yaml",
        site       => $::site,
        class_name => 'role::syslog::centralserver',
        port       => 3903,
    }

    prometheus::class_config{ "mtail_thumbor_haproxy_${::site}":
        dest       => "${targets_path}/mtail_thumbor_haproxy_${::site}.yaml",
        site       => $::site,
        class_name => 'role::thumbor::mediawiki',
        port       => 3903,
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
        port       => 9142,
    }

    $logstash_jobs= [
        {
            'job_name'        => 'logstash',
            'scheme'          => 'http',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/logstash_*.yaml" ]}
            ],
            # logstash auto-generates long random plugin_ids by default, so
            # drop plugin_ids matching the default random plugin_id format
            'metric_relabel_configs' => [
                { 'source_labels' => ['plugin_id'],
                    'regex'  => '(\w{40}-\d+)',
                    'action' => 'drop',
                },
            ],
        },
    ]
    prometheus::class_config { "logstash_${::site}":
        dest       => "${targets_path}/logstash_${::site}.yaml",
        site       => $::site,
        class_name => 'profile::prometheus::logstash_exporter',
        port       => 9198,
    }

    $rsyslog_jobs = [
        {
            'job_name'        => 'rsyslog',
            'scheme'          => 'http',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/rsyslog_*.yaml" ]}
            ],
            # drop metrics for actions without an explicity assigned name
            # to prevent metrics explosion
            'metric_relabel_configs' => [
                { 'source_labels' => ['action'],
                    'regex'  => 'action-\d+-.*(?:.*)',
                    'action' => 'drop',
                },
            ],
        },
    ]
    prometheus::class_config { "rsyslog_${::site}":
        dest       => "${targets_path}/rsyslog_${::site}.yaml",
        site       => $::site,
        class_name => 'profile::prometheus::rsyslog_exporter',
        port       => 9105,
    }

    $pdns_rec_jobs = [
      {
        'job_name'        => 'pdnsrec',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/pdnsrec_*.yaml" ]}
        ],
      },
    ]

    prometheus::class_config{ "pdnsrec_${::site}":
        dest       => "${targets_path}/pdnsrec_${::site}.yaml",
        site       => $::site,
        class_name => 'role::dnsrecursor',
        port       => 9199,
    }

    $elasticsearch_jobs = [
        {
            'job_name'        => 'elasticsearch',
            'scheme'          => 'http',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/elasticsearch_*.yaml" ]}
            ],
        },
    ]
    prometheus::resource_config { "elasticsearch_${::site}":
        dest           => "${targets_path}/elasticsearch_${::site}.yaml",
        site           => $::site,
        define_name    => 'prometheus::elasticsearch_exporter',
        port_parameter => 'prometheus_port',
    }

    $wmf_elasticsearch_jobs = [
        {
            'job_name'        => 'wmf_elasticsearch',
            'scheme'          => 'http',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/wmf_elasticsearch_*.yaml" ]}
            ],
        },
    ]
    prometheus::resource_config { "wmf_elasticsearch_${::site}":
        dest           => "${targets_path}/wmf_elasticsearch_${::site}.yaml",
        site           => $::site,
        define_name    => 'prometheus::wmf_elasticsearch_exporter',
        port_parameter => 'prometheus_port',
    }

    # Job definition for haproxy_exporter
    $haproxy_jobs = [
      {
        'job_name'        => 'haproxy',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/haproxy_*.yaml"] },
        ],
      },
    ]

    prometheus::class_config{ "haproxy_${::site}":
        dest       => "${targets_path}/haproxy_${::site}.yaml",
        site       => $::site,
        class_name => 'profile::prometheus::haproxy_exporter',
        port       => 9901,
    }

    $statsd_exporter_jobs = [
      {
        'job_name'        => 'statsd_exporter',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/statsd_exporter_*.yaml"] },
        ],
      },
    ]

    prometheus::class_config{ "statsd_exporter_${::site}":
        dest       => "${targets_path}/statsd_exporter_${::site}.yaml",
        site       => $::site,
        class_name => 'profile::prometheus::statsd_exporter',
        port       => 9112,
    }

    $nutcracker_jobs = [
        {
            'job_name'        => 'nutcracker',
            'scheme'          => 'http',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/nutcracker_*.yaml" ]}
            ],
        },
    ]
    prometheus::class_config { "nutcracker_${::site}":
        dest       => "${targets_path}/nutcracker_${::site}.yaml",
        site       => $::site,
        class_name => 'profile::prometheus::nutcracker_exporter',
        port       => 9191,
    }

    # Gather postgresql metrics from hosts having the
    # prometheus::postgres_exporter class defined
    $postgresql_jobs = [
      {
        'job_name'        => 'postgresql',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/postgresql_*.yaml" ]}
        ],
      },
    ]
    prometheus::class_config{ "postgresql_${::site}":
        dest       => "${targets_path}/postgresql_${::site}.yaml",
        site       => $::site,
        class_name => 'prometheus::postgres_exporter',
        port       => 9187,
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

    prometheus::class_config{ "burrow_main_${::site}":
        dest       => "${targets_path}/burrow_main_${::site}.yaml",
        site       => $::site,
        class_name => 'role::kafka::monitoring',
        port       => 9500,
    }

    prometheus::class_config{ "burrow_logging_${::site}":
        dest       => "${targets_path}/burrow_logging_${::site}.yaml",
        site       => $::site,
        class_name => 'role::kafka::monitoring',
        port       => 9501,
    }

    prometheus::class_config{ "burrow_jumbo_${::site}":
        dest       => "${targets_path}/burrow_jumbo_${::site}.yaml",
        site       => $::site,
        class_name => 'role::kafka::monitoring',
        port       => 9700,
    }

    $mjolnir_jobs = [
        {
            'job_name'        => 'mjolnir',
            'scheme'          => 'http',
            'file_sd_configs' => [
                { 'files'     => [ "${targets_path}/mjolnir_*.yaml" ]}
            ],
        },
    ]
    prometheus::class_config { "mjolnir_bulk_${::site}}.yaml":
        dest       => "${targets_path}/mjolnir_bulk_${::site}.yaml",
        site       => $::site,
        class_name => 'profile::mjolnir::kafka_bulk_daemon',
        port       => 9170,
    }
    prometheus::class_config { "mjolnir_msearch_${::site}}.yaml":
        dest       => "${targets_path}/mjolnir_msearch_${::site}.yaml",
        site       => $::site,
        class_name => 'profile::mjolnir::kafka_msearch_daemon',
        port       => 9171,
    }


    prometheus::server { 'ops':
        listen_address        => '127.0.0.1:9900',
        storage_retention     => $storage_retention,
        max_chunks_to_persist => $max_chunks_to_persist,
        memory_chunks         => $memory_chunks,
        scrape_configs_extra  => array_concat(
            $mysql_jobs, $varnish_jobs, $trafficserver_jobs, $memcached_jobs, $hhvm_jobs,
            $apache_jobs, $etcd_jobs, $etcdmirror_jobs, $mcrouter_jobs, $pdu_jobs,
            $nginx_jobs, $pybal_jobs, $blackbox_jobs, $jmx_exporter_jobs,
            $redis_jobs, $mtail_jobs, $ldap_jobs, $ircd_jobs, $pdns_rec_jobs,
            $etherpad_jobs, $elasticsearch_jobs, $wmf_elasticsearch_jobs,
            $blazegraph_jobs, $nutcracker_jobs, $postgresql_jobs,
            $kafka_burrow_jobs, $logstash_jobs, $haproxy_jobs, $statsd_exporter_jobs,
            $mjolnir_jobs, $rsyslog_jobs, $php_jobs, $php_fpm_jobs, $icinga_jobs, $docker_registry_jobs,
            $gerrit_jobs, $routinator_jobs, $rpkicounter_jobs, $varnishkafka_jobs
        ),
        global_config_extra   => $config_extra,
    }

    monitoring::check_prometheus { 'prometheus_config_reload_fail':
        description     => 'Prometheus configuration reload failure',
        query           => 'prometheus_config_last_reload_successful',
        method          => 'eq',
        warning         => 0,
        critical        => 0,
        # Check each Prometheus server host individually, not through the LVS service IP
        prometheus_url  => "http://${::fqdn}/ops",
        dashboard_links => ["https://grafana.wikimedia.org/dashboard/db/host-overview?var-server=${::hostname}&var-datasource=${::site} prometheus/ops"],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Prometheus#Configuration_reload_failure',
    }

    prometheus::web { 'ops':
        proxy_pass => 'http://localhost:9900/ops',
    }

    file { '/srv/prometheus/ops/gerrit.token':
        ensure  => present,
        content => $gerrit_client_token,
        mode    => '0400',
        owner   => 'prometheus',
        group   => 'prometheus',
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

    prometheus::rule { 'rules_ops.yml':
        instance => 'ops',
        source   => 'puppet:///modules/role/prometheus/rules_ops.yml',
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

    # Used for  migrations / hardware refresh, but not continuously
    rsync::server::module { 'prometheus-ops':
        ensure         => absent,
        path           => '/srv/prometheus/ops/metrics',
        uid            => 'prometheus',
        gid            => 'prometheus',
        hosts_allow    => hiera('prometheus_nodes'),
        auto_ferm      => true,
        auto_ferm_ipv6 => true,
    }

}
