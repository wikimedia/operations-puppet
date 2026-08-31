# SPDX-License-Identifier: Apache-2.0
class profile::prometheus::cloud (
    String $openstack_deployment = lookup('profile::prometheus::cloud::openstack_deployment'),
    Array $alertmanagers = lookup('alertmanagers', {'default_value' => []}),
    String $replica_label = lookup('prometheus::replica_label'),
    String $maintain_dbusers_primary = lookup('wmcs_maintain_dbusers_primary'),
) {
    $instance = 'cloud'
    $config = prometheus::instance_config($instance)
    $targets_path = $config['targets_path']
    $port = $config['port']
    $storage_retention = $config['retention_time']
    $storage_retention_size = $config['retention_size']
    $thanos_upload = $config['thanos_upload']

    $config_extra = {
        'external_labels' => {
            'site'       => $::site,
            'replica'    => $replica_label,
            'prometheus' => $instance,
        },
    }

    $blackbox_jobs = [
        {
            'job_name'        => 'blackbox_http',
            'metrics_path'    => '/probe',
            'params'          => {
                'module' => [ 'http_200_300_connect' ],
            },
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/blackbox_http_*.yaml" ] }
            ],
            'relabel_configs' => [
                { 'source_labels' => ['__address__'],
                    'target_label'  => '__param_target',
                    'replacement' => 'http://$1/',
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
                'module' => [ 'https_200_300_connect' ],
            },
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/blackbox_https_*.yaml" ] }
            ],
            'relabel_configs' => [
                { 'source_labels' => ['__address__'],
                    'target_label'  => '__param_target',
                    'replacement' => 'https://$1/',
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

    $jmx_exporter_jobs = [
        {
            'job_name'        => 'jmx_zookeeper',
            'scheme'          => 'http',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/jmx_zookeeper_*.yaml" ]}
            ],
        },
    ]

    $rabbitmq_jobs = [
        {
            'job_name'        => 'rabbitmq',
            'scheme'          => 'http',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/rabbitmq_*.yaml" ] }
            ],
        },
    ]

    $pdns_jobs = [
        {
            'job_name'        => 'pdns',
            'scheme'          => 'http',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/pdns_*.yaml" ] }
            ],
        },
    ]

    $pdns_rec_jobs = [
        {
            'job_name'        => 'pdns_rec',
            'scheme'          => 'http',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/pdns-rec_*.yaml" ] }
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

    $openstack_jobs = [
        {
            'job_name'        => 'openstack',
            'scheme'          => 'http',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/openstack_*.yaml" ] }
            ],
            'metric_relabel_configs' => [
                $hostname_to_instance_config,
            ],
            # this number is controversial and may have a high impact on the APIs
            # see T335943
            'scrape_interval' => '4m',
            'scrape_timeout'  => '120s',
        },
    ]

    $ceph_jobs = [
        {
            'job_name'        => "ceph_${::site}",
            'scheme'          => 'http',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/ceph_${::site}.yaml" ]}
            ],
            'metric_relabel_configs' => [
                $hostname_to_instance_config,
            ],
            'scrape_timeout'  => '30s',
        },
    ]

    $maintain_dbusers_jobs = [
        {
            'job_name'        => "maintain_dbusers_${::site}",
            'scheme'          => 'http',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/maintain_dbusers_*.yaml" ]}
            ],
            'metric_relabel_configs' => [
                $hostname_to_instance_config,
            ],
        },
    ]

    if $maintain_dbusers_primary =~ $::site {
        file { "${targets_path}/maintain_dbusers_${openstack_deployment}.yaml":
            content => to_yaml([{
                'labels'  => {
                    'deployment' => $openstack_deployment,
                },
                'targets' => [
                    "${maintain_dbusers_primary}:9090",
                ],
            }]),
        }
    }

    # https://phabricator.wikimedia.org/T348643#9916509
    file { "${targets_path}/ebpf_exporter_osds.yaml":
        ensure => absent,
    }

    file { "${targets_path}/blackbox_http_keystone.yaml":
        content => to_yaml([{
            'labels'  => {
                'deployment' => $openstack_deployment,
            },
            'targets' => [
                "openstack.${openstack_deployment}.wikimediacloud.org:5000/v3", # keystone
            ],
        }]),
    }

    file { "${targets_path}/blackbox_https_keystone.yaml":
        content => to_yaml([{
            'labels'  => {
                'deployment' => $openstack_deployment,
            },
            'targets' => [
                "openstack.${openstack_deployment}.wikimediacloud.org:25000/v3", # keystone
                "openstack.${openstack_deployment}.wikimediacloud.org:28774", # nova
                "openstack.${openstack_deployment}.wikimediacloud.org:28776", # cinder
                "openstack.${openstack_deployment}.wikimediacloud.org:28778", # placement
                "openstack.${openstack_deployment}.wikimediacloud.org:28779", # trove
                "openstack.${openstack_deployment}.wikimediacloud.org:29001", # designate
                "openstack.${openstack_deployment}.wikimediacloud.org:29292", # glance
                "openstack.${openstack_deployment}.wikimediacloud.org:29696", # neutron
            ],
        }]),
    }

    prometheus::jmx_exporter_config{ "zookeeper_cloud_${::site}":
        dest       => "${targets_path}/jmx_zookeeper_${::site}.yaml",
        class_name => "role::wmcs::openstack::${openstack_deployment}::control",
        labels     => {'deployment' => $openstack_deployment},
    }

    prometheus::class_config{ "rabbitmq_${::site}":
        dest       => "${targets_path}/rabbitmq_${::site}.yaml",
        class_name => "profile::openstack::${openstack_deployment}::rabbitmq",
        labels     => {'deployment' => $openstack_deployment},
        port       => 15692,
    }

    prometheus::class_config{ "pdns_${::site}":
        dest       => "${targets_path}/pdns_${::site}.yaml",
        class_name => "role::wmcs::openstack::${openstack_deployment}::services",
        labels     => {'deployment' => $openstack_deployment},
        port       => 8081,
    }

    prometheus::class_config{ "pdns-rec_${::site}":
        dest       => "${targets_path}/pdns-rec_${::site}.yaml",
        class_name => "role::wmcs::openstack::${openstack_deployment}::services",
        labels     => {'deployment' => $openstack_deployment},
        port       => 8082,
    }

    prometheus::class_config { "openstack_${::site}":
        dest             => "${targets_path}/openstack_${::site}.yaml",
        class_name       => 'profile::prometheus::openstack_exporter',
        class_parameters => {'ensure' => 'present', 'cloud' => $openstack_deployment},
        labels           => {'deployment' => $openstack_deployment},
        port             => 12345,
    }

    prometheus::class_config{ "ceph_${::site}":
        dest       => "${targets_path}/ceph_${::site}.yaml",
        class_name => 'role::wmcs::ceph::mon',
        port       => 9283,
    }

    prometheus::class_config { "mysql_galera_${openstack_deployment}":
        dest       => "${targets_path}/mysql_galera_${openstack_deployment}.yaml",
        class_name => "role::wmcs::openstack::${openstack_deployment}::control",
        labels     => {'deployment' => $openstack_deployment},
        port       => 9104,
    }

    $galera_jobs = [
        {
            'job_name'        => 'mysql-galera',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/mysql_galera_*.yaml"] },
            ],
        }
    ]

    # Job definition for cloudlb haproxy
    $cloudlb_haproxy_jobs = [
        {
            'job_name'        => 'cloudlb-haproxy',
            'scheme'          => 'http',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/cloudlb_haproxy_*.yaml"] },
            ],
        },
    ]

    prometheus::class_config { "cloudlb_haproxy_${::site}":
        dest       => "${targets_path}/cloudlb_haproxy_${::site}.yaml",
        class_name => 'profile::wmcs::cloudlb::haproxy',
        port       => 9900,
    }

    prometheus::prometheus_cardinality_exporter { $instance:
        exporter_port    => $config['cardinality_exporter']['port'],
        prometheus_url   => "http://127.0.0.1:${port}/${instance}",
        polling_interval => $config['cardinality_exporter']['polling_interval'],
    }

    prometheus::resource_config{ "prometheus_cardinality_exporter_${instance}_${::site}":
        dest           => "${targets_path}/prometheus_cardinality_exporter_${::site}.yaml",
        define_name    => 'prometheus::prometheus_cardinality_exporter',
        resource_title => $instance,
        port_parameter => 'exporter_port',
    }

    $prometheus_cardinality_exporter_jobs = [
      {
        'job_name'               => 'prometheus_cardinality_exporter',
        'file_sd_configs'        => [
          { 'files' => ["${targets_path}/prometheus_cardinality_exporter_*.yaml"]},
        ],
        'metric_relabel_configs' => [
          {
            'regex'  => '(sharded|scraped)_instance',
            'action' => 'labeldrop',
          },
          {
            'regex'  => 'instance_namespace',
            'action' => 'labeldrop',
          },
        ],
      },
    ]

    prometheus::server { $instance:
        listen_address                 => "127.0.0.1:${port}",
        storage_retention              => $storage_retention,
        storage_retention_size         => $storage_retention_size,
        alertmanagers                  => $alertmanagers.map |$a| { "${a}:9093" },
        alerting_relabel_configs_extra => [
            # Add 'team' label, https://phabricator.wikimedia.org/T302493#7759642
            { 'target_label' => 'team', 'replacement' => 'wmcs', 'action' => 'replace' },
        ],
        scrape_configs_extra           => [
            $blackbox_jobs, $rabbitmq_jobs, $pdns_jobs,
            $pdns_rec_jobs, $openstack_jobs, $ceph_jobs,
            $galera_jobs, $cloudlb_haproxy_jobs,
            $maintain_dbusers_jobs, $jmx_exporter_jobs,
            $prometheus_cardinality_exporter_jobs,
        ].flatten,
        global_config_extra            => $config_extra,
        rule_files_extra               => ['/srv/alerts/cloud/*.yaml'],
    }

    profile::thanos::sidecar { $instance:
        prometheus_port     => $port,
        prometheus_instance => $instance,
        enable_upload       => $thanos_upload,
    }

    # Checks for alerting rules, defined in puppet
    prometheus::alert::import { $instance: }

    prometheus::pint::source { $instance:
        port => $port,
    }
}
