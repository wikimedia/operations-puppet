# SPDX-License-Identifier: Apache-2.0
class profile::prometheus::cloud (
    String $openstack_deployment = lookup('profile::prometheus::cloud::openstack_deployment'),
    String $storage_retention = lookup('profile::prometheus::cloud::storage_retention', {'default_value' => '4032h'}),
    Optional[Stdlib::Datasize] $storage_retention_size = lookup('profile::prometheus::cloud::storage_retention_size', {default_value => undef}),
    Array $alertmanagers = lookup('alertmanagers', {'default_value' => []}),
    Boolean $enable_thanos_upload     = lookup('profile::prometheus::enable_thanos_upload', { 'default_value' => false }),
    Optional[String] $thanos_min_time = lookup('profile::prometheus::thanos::min_time', { 'default_value' => undef }),
    String $replica_label = lookup('prometheus::replica_label'),
) {
    $targets_path = '/srv/prometheus/cloud/targets'

    $config_extra = {
        'external_labels' => {
            'site'       => $::site,
            'replica'    => $replica_label,
            'prometheus' => 'cloud',
        },
    }

    $port = 9904

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
        },
    ]


    # https://phabricator.wikimedia.org/T348643#9916509
    if $::site == 'eqiad' {
        $ebpf_exporter_jobs = [
            {
                'job_name'        => "ebpf_exporter_${::site}",
                'scheme'          => 'http',
                'file_sd_configs' => [
                    { 'files' => [ "${targets_path}/ebpf_exporter_*.yaml" ]}
                ],
            },
        ]
        file { "${targets_path}/ebpf_exporter_osds.yaml":
            content => to_yaml([{
                'labels'  => {
                    'deployment' => $openstack_deployment,
                },
                'targets' => [
                    'cloudcephosd1034:9435',
                    'cloudcephosd1010:9435',
                ],
            }]),
        }
    } else {
        $ebpf_exporter_jobs = []
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

    prometheus::server { 'cloud':
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
            $galera_jobs, $cloudlb_haproxy_jobs, $ebpf_exporter_jobs,
        ].flatten,
        global_config_extra            => $config_extra,
        rule_files_extra               => ['/srv/alerts/cloud/*.yaml'],
    }

    profile::thanos::sidecar { 'cloud':
        prometheus_port     => $port,
        prometheus_instance => 'cloud',
        enable_upload       => $enable_thanos_upload,
        min_time            => $thanos_min_time,
    }

    prometheus::pint::source { 'cloud':
        port => $port,
    }

    prometheus::web { 'cloud':
        proxy_pass => "http://localhost:${port}/cloud",
    }
}
