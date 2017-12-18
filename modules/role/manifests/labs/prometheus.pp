
class role::labs::prometheus {
    $targets_path = '/srv/prometheus/labs/targets'
    $storage_retention = hiera('prometheus::server::storage_retention', '2190h0m0s')
    $max_chunks_to_persist = hiera('prometheus::server::max_chunks_to_persist', '524288')
    $memory_chunks = hiera('prometheus::server::memory_chunks', '1048576')

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

    file { "${targets_path}/blackbox_http_keystone.yaml":
      content => ordered_yaml([{
        'targets' => ['labcontrol1001.wikimedia.org:5000/v3', # keystone
                      'labcontrol1001.wikimedia.org:9292', # glance
                      'labservices1001.wikimedia.org:9001', # designate
                      'labnet1001.eqiad.wmnet:8774', # nova
                      'proxy-eqiad.wmflabs.org:5668', # proxy
            ]
        }]),
    }

    prometheus::class_config{ "rabbitmq_${::site}":
        dest       => "${targets_path}/rabbitmq_${::site}.yaml",
        site       => $::site,
        class_name => 'role::wmcs::openstack::main::control',
        port       => '9195',
    }

    prometheus::class_config{ "pdns_${::site}":
        dest       => "${targets_path}/pdns_${::site}.yaml",
        site       => $::site,
        class_name => 'role::wmcs::openstack::main::services_primary',
        port       => '9192',
    }

    prometheus::server { 'labs':
        storage_encoding      => '2',
        listen_address        => ':9900',
        storage_retention     => $storage_retention,
        max_chunks_to_persist => $max_chunks_to_persist,
        memory_chunks         => $memory_chunks,
        scrape_configs_extra  => array_concat(
            $blackbox_jobs, $rabbitmq_jobs, $pdns_jobs,
        ),
    }

    prometheus::web { 'labs':
        proxy_pass => 'http://localhost:9900/labs',
    }


    ferm::service { 'prometheus-web':
        proto  => 'tcp',
        port   => '80',
        srange => '$DOMAIN_NETWORKS',
    }
}
