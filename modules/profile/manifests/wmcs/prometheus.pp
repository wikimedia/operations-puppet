class profile::wmcs::prometheus(
    Stdlib::Unixpath $targets_path = '/srv/prometheus/labs/targets',
    String $storage_retention = lookup('prometheus::server::storage_retention', {'default_value' => '4032h'}),
    Integer $max_chunks_to_persist = lookup('prometheus::server::max_chunks_to_persist', {'default_value' => 524288}),
    Integer $memory_chunks = lookup('prometheus::server::memory_chunks', {'default_value' => 1048576}),
    Optional[Stdlib::Datasize] $storage_retention_size = lookup('profile::wmcs::prometheus::storage_retention_size',   {default_value => undef}),
    Array[Stdlib::Host] $alertmanagers = lookup('alertmanagers', {'default_value' => []}),
) {
    $config_extra = {
        'external_labels' => {
            # right now cloudmetrics hardware only exists on eqiad1, make sure to update this if that changes
            'deployment' => 'eqiad1',
            'prometheus' => 'cloud',
        },
    }

    include ::prometheus::blackbox_exporter
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

    $openstack_jobs = [
        {
            'job_name'        => 'openstack',
            'scheme'          => 'http',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/openstack_*.yaml" ] }
            ],
            'scrape_interval' => '15m',
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
      },
    ]

    file { "${targets_path}/blackbox_http_keystone.yaml":
        content => to_yaml([{
            'targets' => [
                'openstack.eqiad1.wikimediacloud.org:5000/v3', # keystone
            ],
        }]),
    }

    file { "${targets_path}/blackbox_https_keystone.yaml":
        content => to_yaml([{
            'targets' => [
                'openstack.eqiad1.wikimediacloud.org:25000/v3', # keystone
                'openstack.eqiad1.wikimediacloud.org:28774', # nova
                'openstack.eqiad1.wikimediacloud.org:28776', # cinder
                'openstack.eqiad1.wikimediacloud.org:28778', # placement
                'openstack.eqiad1.wikimediacloud.org:28779', # trove
                'openstack.eqiad1.wikimediacloud.org:29001', # designate
                'openstack.eqiad1.wikimediacloud.org:29292', # glance
                'openstack.eqiad1.wikimediacloud.org:29696', # neutron
            ],
        }]),
    }

    prometheus::class_config{ "rabbitmq_${::site}":
        dest       => "${targets_path}/rabbitmq_${::site}.yaml",
        class_name => 'role::wmcs::openstack::eqiad1::control',
        port       => 15692,
    }

    prometheus::class_config{ "pdns_${::site}":
        dest       => "${targets_path}/pdns_${::site}.yaml",
        class_name => 'role::wmcs::openstack::eqiad1::services',
        port       => 8081,
    }

    prometheus::class_config{ "pdns-rec_${::site}":
        dest       => "${targets_path}/pdns-rec_${::site}.yaml",
        class_name => 'role::wmcs::openstack::eqiad1::services',
        port       => 8082,
    }

    file { "${targets_path}/openstack_${::site}.yaml":
        content => to_yaml([{
            'labels'  => {
                'cluster' => 'wmcs',
                'site'    => 'eqiad',
            },
            'targets' => [
                'openstack.eqiad1.wikimediacloud.org:12345',
            ]
        }]),
    }

    file { "${targets_path}/redis_toolforge_hosts.yaml":
        ensure => absent,
    }

    prometheus::class_config{ "ceph_${::site}":
        dest       => "${targets_path}/ceph_${::site}.yaml",
        class_name => 'role::wmcs::ceph::mon',
        port       => 9283,
    }

    # Don't worry about codfw1dev; no cloudmetrics in codfw anyway
    if $::site == eqiad {
        prometheus::class_config{ 'mysql_galera_eqiad1':
            dest       => "${targets_path}/mysql_galera_eqiad1.yaml",
            class_name => 'role::wmcs::openstack::eqiad1::control',
            port       => 9104,
            labels     => {
                'deployment' => 'eqiad1'
            }
        }
    }

    $galera_jobs = [
        {
            'job_name'        => 'mysql-galera',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/mysql_galera_*.yaml"] },
            ],
        }
    ]

    prometheus::server { 'labs':
        listen_address                 => '127.0.0.1:9900',
        storage_retention              => $storage_retention,
        storage_retention_size         => $storage_retention_size,
        max_chunks_to_persist          => $max_chunks_to_persist,
        memory_chunks                  => $memory_chunks,
        alertmanagers                  => $alertmanagers.map |$a| { "${a}:9093" },
        alerting_relabel_configs_extra => [
            # Add 'team' label, https://phabricator.wikimedia.org/T302493#7759642
            { 'target_label' => 'team', 'replacement' => 'wmcs', 'action' => 'replace' },
        ],
        scrape_configs_extra           => [
            $blackbox_jobs, $rabbitmq_jobs, $pdns_jobs,
            $pdns_rec_jobs, $openstack_jobs, $ceph_jobs,
            $galera_jobs,
        ].flatten,
        global_config_extra            => $config_extra,
        rule_files_extra               => ['/srv/alerts/cloud/*.yaml'],
    }

    class { 'alerts::deploy::prometheus':
        # let's not introduce new uses of the 'labs' term in operations/alerts.git
        instances => ['cloud'],
    }

    httpd::site{ 'prometheus':
        priority => 10,
        content  => template('profile/wmcs/metricsinfra/prometheus-apache.erb'),
    }

    prometheus::web { 'labs':
        proxy_pass => 'http://localhost:9900/labs',
        require    => Httpd::Site['prometheus'],
    }

    ferm::service { 'prometheus-web':
        proto  => 'tcp',
        port   => '80',
        srange => '$DOMAIN_NETWORKS',
    }
}
