# prometheus instance for PAWS
class profile::wmcs::paws::prometheus (
    Optional[Stdlib::Datasize] $storage_retention_size = lookup('profile::wmcs::paws::prometheus::storage_retention_size',   {default_value => undef}),
    String                     $region                 = lookup('profile::openstack::eqiad1::region'),
    Stdlib::Fqdn               $keystone_api_fqdn      = lookup('profile::openstack::eqiad1::keystone_api_fqdn'),
    String                     $observer_user          = lookup('profile::openstack::base::observer_user'),
    String                     $observer_password      = lookup('profile::openstack::eqiad1::observer_password'),
    Stdlib::Fqdn               $k8s_apiserver_fqdn     = lookup('profile::wmcs::paws::prometheus::k8s_apiserver_fqdn', {default_value => 'k8s.svc.paws.eqiad1.wikimedia.cloud'}),
    Stdlib::Port               $k8s_apiserver_port     = lookup('profile::wmcs::paws::prometheus::k8s_apiserver_port',      {default_value => 6443}),
) {
    include ::profile::labs::cindermount::srv

    class { '::httpd':
        modules => ['proxy', 'proxy_http'],
    }

    $k8s_cert_name  = 'paws-k8s-prometheus'
    $k8s_cert_pub  = "/etc/ssl/localcerts/${k8s_cert_name}.crt"
    $k8s_cert_priv = "/etc/ssl/private/${k8s_cert_name}.key"
    sslcert::certificate { $k8s_cert_name:
        ensure  => present,
        chain   => false,
        group   => 'prometheus',
        require => Package['prometheus'], # group is defined by the package?
        notify  => Service['prometheus@paws'],
    }

    $k8s_tls_config = {
        'insecure_skip_verify' => true,
        'cert_file'            => $k8s_cert_pub,
        'key_file'             => $k8s_cert_priv,
    }

    $openstack_jobs = [
        {
            name => 'node-exporter',
            port => 9100,
        },
        {
            name            => 'haproxy',
            port            => 9901,
            instance_filter => 'paws-k8s-haproxy-\\d+',
        },
        {
            name            => 'k8s-apiserver',
            port            => 6443,
            instance_filter => 'paws-k8s-control-\\d+',
            extra_config    => {
                scheme     => 'https',
                tls_config => $k8s_tls_config,
            },
        }
    ].map |Hash $job| {
        if $job['instance_filter'] {
            $relabel_configs = [
                {
                    'source_labels' => ['__meta_openstack_instance_name'],
                    'action'        => 'keep',
                    'regex'         => $job['instance_filter'],
                },
                {
                    'source_labels' => ['__meta_openstack_instance_name'],
                    'target_label'  => 'instance',
                },
                {
                    'source_labels' => ['__meta_openstack_instance_status'],
                    'action'        => 'keep',
                    'regex'         => 'ACTIVE',
                },
            ]
        } else {
            $relabel_configs = [
                {
                    'source_labels' => ['__meta_openstack_instance_name'],
                    'target_label'  => 'instance',
                },
                {
                    'source_labels' => ['__meta_openstack_instance_status'],
                    'action'        => 'keep',
                    'regex'         => 'ACTIVE',
                },
            ]
        }

        $result = {
            'job_name'             => $job['name'],
            'openstack_sd_configs' => [
                {
                    'role'              => 'instance',
                    'region'            => $region,
                    'identity_endpoint' => "https://${keystone_api_fqdn}:25000/v3",
                    'username'          => $observer_user,
                    'password'          => $observer_password,
                    'domain_name'       => 'default',
                    'project_name'      => $::labsproject,
                    'all_tenants'       => false,
                    'refresh_interval'  => '5m',
                    'port'              => $job['port'],
                }
            ],
            'relabel_configs'      => $relabel_configs,
        }

        deep_merge(
            $result,
            pick($job['extra_config'], {})
        )
    }

    $manual_jobs = [
        {
            'job_name'       => 'jupyterhub',
            'scheme'         => 'https',
            'metrics_path'   => '/hub/metrics',
            'static_configs' => [
                {
                    'targets' => ['hub.paws.wmcloud.org'],
                },
            ],
        },

        # this is in manual and not $kubernetes_pod_jobs
        # as it scrapes nodes, not jobs
        {
            'job_name'              => 'k8s-nodes',
            'scheme'                => 'https',
            'tls_config'            => $k8s_tls_config,
            'kubernetes_sd_configs' => [
                {
                    'api_server' => "https://${k8s_apiserver_fqdn}:${k8s_apiserver_port}",
                    'role'       => 'node',
                    'tls_config' => $k8s_tls_config,
                },
            ],
            'relabel_configs'       => [
                {
                    'action' => 'labelmap',
                    'regex'  => '__meta_kubernetes_node_label_(.+)',
                },
                {
                    'target_label' => '__address__',
                    'replacement'  => "${k8s_apiserver_fqdn}:${k8s_apiserver_port}",
                },
                {
                    'source_labels' => ['__meta_kubernetes_node_name'],
                    'regex'         => '(.+)',
                    'target_label'  => '__metrics_path__',
                    # lint:ignore:single_quote_string_with_variables
                    'replacement'   => '/api/v1/nodes/${1}/proxy/metrics',
                    # lint:endignore
                },
            ]
        },
    ]

    $kubernetes_pod_jobs = [
        {
            name      => 'k8s-ingress-nginx',
            namespace => 'ingress-nginx-gen2',
            pod_name  => 'ingress-nginx-gen2-controller-[a-zA-Z0-9]+-[a-zA-Z0-9]+',
            port      => 10254,
        },
        {
            name      => 'k8s-cadvisor',
            namespace => 'metrics',
            pod_name  => 'cadvisor-[a-zA-Z0-9]+',
            port      => 8080,
        },
        {
            name      => 'k8s-kube-state-metrics',
            namespace => 'metrics',
            pod_name  => 'kube-state-metrics-[a-zA-Z0-9]+-[a-zA-Z0-9]+',
            port      => 8080,
        },
    ].map |Hash $job| {
        {
            'job_name'              => $job['name'],
            'scheme'                => 'https',
            'tls_config'            => $k8s_tls_config,
            'kubernetes_sd_configs' => [
                {
                    'api_server' => "https://${k8s_apiserver_fqdn}:${k8s_apiserver_port}",
                    'role'       => 'pod',
                    'tls_config' => $k8s_tls_config,
                    'namespaces' => {
                        'names' => [
                            $job['namespace'],
                        ],
                    },
                },
            ],
            'relabel_configs'       => [
                {
                    'action'        => 'keep',
                    'regex'         => $job['pod_name'],
                    'source_labels' => ['__meta_kubernetes_pod_name'],
                },
                {
                    'target_label' => '__address__',
                    'replacement'  => "${k8s_apiserver_fqdn}:${k8s_apiserver_port}",
                },
                {
                    'source_labels' => ['__meta_kubernetes_pod_name'],
                    'regex'         => "(${job['pod_name']})",
                    'target_label'  => '__metrics_path__',
                    'replacement'   => "/api/v1/namespaces/${job['namespace']}/pods/\${1}:${job['port']}/proxy/metrics",
                },
            ]
        }
    }

    $jobs = $openstack_jobs + $manual_jobs + $kubernetes_pod_jobs

    $alertmanager_discovery_extra = [
        {
            'openstack_sd_configs' => [
                {
                    'role'              => 'instance',
                    'region'            => $region,
                    'identity_endpoint' => "https://${keystone_api_fqdn}:25000/v3",
                    'username'          => $observer_user,
                    'password'          => $observer_password,
                    'domain_name'       => 'default',
                    'project_name'      => 'metricsinfra',
                    'all_tenants'       => false,
                    'refresh_interval'  => '5m',
                    'port'              => 8643,
                },
            ],
            'relabel_configs'      => [
                {
                    'source_labels' => ['__meta_openstack_instance_name'],
                    'action'        => 'keep',
                    'regex'         => 'metricsinfra-alertmanager-\d+',
                },
                {
                    'source_labels' => ['__meta_openstack_instance_name'],
                    'target_label'  => 'instance',
                },
                {
                    'source_labels' => ['__meta_openstack_instance_status'],
                    'action'        => 'keep',
                    'regex'         => 'ACTIVE',
                },
            ],
        },
    ]

    prometheus::server { 'paws':
        listen_address                 => '127.0.0.1:9903',
        external_url                   => 'https://prometheus.paws.wmcloud.org/paws',
        storage_retention_size         => $storage_retention_size,
        scrape_configs_extra           => $jobs,
        alertmanager_discovery_extra   => $alertmanager_discovery_extra,
        alerting_relabel_configs_extra => [
            { 'target_label' => 'project', 'replacement' => $::labsproject, 'action' => 'replace' },
        ],
    }

    prometheus::web { 'paws':
        proxy_pass => 'http://localhost:9903/paws',
    }
}
