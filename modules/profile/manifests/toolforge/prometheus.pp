# This profile provides both project-wide host discovery/monitoring (via cron
# prometheus-labs-targets) and kubernetes discovery/monitoring via Prometheus'
# native k8s support.

class profile::toolforge::prometheus (
    Stdlib::Fqdn               $new_k8s_apiserver_fqdn = lookup('profile::toolforge::k8s::apiserver_fqdn', {default_value => 'k8s.tools.eqiad1.wikimedia.cloud'}),
    Stdlib::Fqdn               $paws_apiserver_fqdn    = lookup('profile::wmcs::paws::k8s::apiserver_fqdn', {default_value => 'k8s.svc.paws.eqiad1.wikimedia.cloud'}),
    Stdlib::Port               $new_k8s_apiserver_port = lookup('profile::toolforge::k8s::apiserver_port', {default_value => 6443}),
    Stdlib::Port               $paws_apiserver_port    = lookup('profile::wmcs::paws::apiserver_port',     {default_value => 6443}),
    Stdlib::Fqdn               $keystone_api_fqdn      = lookup('profile::openstack::eqiad1::keystone_api_fqdn'),
    String                     $observer_password      = lookup('profile::openstack::eqiad1::observer_password'),
    String                     $observer_user          = lookup('profile::openstack::base::observer_user'),
    Array[Stdlib::Fqdn]        $proxies                = lookup('profile::toolforge::proxies',             {default_value => ['tools-proxy-05.tools.eqiad.wmflabs']}),
    Stdlib::Fqdn               $email_server           = lookup('profile::toolforge::active_mail_relay',   {default_value => 'tools-mail-02.tools.eqiad1.wikimedia.cloud'}),
    Optional[Stdlib::Datasize] $storage_retention_size = lookup('profile::toolforge::prometheus::storage_retention_size',   {default_value => undef}),
) {
    require ::profile::labs::lvm::srv
    include ::profile::prometheus::blackbox_exporter

    class { '::prometheus::wmcs_scripts': }

    $targets_path = '/srv/prometheus/tools/targets'

    class { '::httpd':
        modules => ['proxy', 'proxy_http'],
    }

    # the certs are used by prometheus to auth to the k8s API and are
    # generated in the k8s control nodes using the wmcs-k8s-get-cert script
    $toolforge_certname  = 'toolforge-k8s-prometheus'
    $cert_pub  = "/etc/ssl/localcerts/${toolforge_certname}.crt"
    $cert_priv = "/etc/ssl/private/${toolforge_certname}.key"
    sslcert::certificate { $toolforge_certname:
        ensure  => present,
        chain   => false,
        group   => 'prometheus',
        require => Package['prometheus'], # group is defined by the package?
        notify  => Service['prometheus@tools'],
    }
    $paws_certname  = 'paws-k8s-prometheus'
    $paws_cert_pub  = "/etc/ssl/localcerts/${paws_certname}.crt"
    $paws_cert_priv = "/etc/ssl/private/${paws_certname}.key"
    sslcert::certificate { $paws_certname:
        ensure  => present,
        chain   => false,
        group   => 'prometheus',
        require => Package['prometheus'], # group is defined by the package?
        notify  => Service['prometheus@tools'],
    }

    prometheus::server { 'tools':
        listen_address         => '127.0.0.1:9902',
        external_url           => 'https://tools-prometheus.wmflabs.org/tools',
        storage_retention_size => $storage_retention_size,
        scrape_configs_extra   => [
            {
                'job_name'        => 'ssh_banner',
                'metrics_path'    => '/probe',
                'params'          => {
                    'module' => ['ssh_banner'],
                },
                'file_sd_configs' => [
                    {
                        'files' => ["${targets_path}/ssh_banner.yml"]
                    }
                ],
                'relabel_configs' => [
                    # The replacement syntax is for prometheus to consume
                    # lint:ignore:single_quote_string_with_variables
                    {
                        'source_labels' => ['__address__'],
                        'regex'         => '(.*)',
                        'target_label'  => '__param_target',
                        'replacement'   => '${1}',
                    },
                    {
                        'source_labels' => ['__param_target'],
                        'regex'         => '(.*)',
                        'target_label'  => 'instance',
                        'replacement'   => '${1}',
                    },
                    {
                        'source_labels' => [],
                        'regex'         => '.*',
                        'target_label'  => '__address__',
                        'replacement'   => '127.0.0.1:9115',
                    }
                    # lint:endignore
                ]
            },
            {
            'job_name'        => 'etcd',
            'file_sd_configs' => [
                {
                    'files' => [ "${targets_path}/etcd_*.yml" ]
                }
            ]
            },
            {
            'job_name'        => 'toolsdb-mariadb',
            'file_sd_configs' => [
                {
                    'files' => [ "${targets_path}/toolsdb-mariadb.yml" ]
                }
            ]
            },
            {
            'job_name'        => 'toolsdb-node',
            'file_sd_configs' => [
                {
                    'files' => [ "${targets_path}/toolsdb-node.yml" ]
                }
            ]
            },
            {
                'job_name'              => 'new-k8s-nodes',
                'scheme'                => 'https',
                'tls_config'            => {
                    'insecure_skip_verify' => true,
                    'cert_file'            => $cert_pub,
                    'key_file'             => $cert_priv,
                },
                'kubernetes_sd_configs' => [
                    {
                        'api_server' => "https://${new_k8s_apiserver_fqdn}:${new_k8s_apiserver_port}",
                        'role'       => 'node',
                        'tls_config' => {
                            'insecure_skip_verify' => true,
                            'cert_file'            => $cert_pub,
                            'key_file'             => $cert_priv,
                        },
                    },
                ],
                'relabel_configs'       => [
                    {
                        'action' => 'labelmap',
                        'regex'  => '__meta_kubernetes_node_label_(.+)',
                    },
                    {
                        'target_label' => '__address__',
                        'replacement'  => "${new_k8s_apiserver_fqdn}:${new_k8s_apiserver_port}",
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
            {
                'job_name'              => 'new-k8s-ingress-nginx',
                'scheme'                => 'https',
                'tls_config'            => {
                    'insecure_skip_verify' => true,
                    'cert_file'            => $cert_pub,
                    'key_file'             => $cert_priv,
                },
                'kubernetes_sd_configs' => [
                    {
                        'api_server' => "https://${new_k8s_apiserver_fqdn}:${new_k8s_apiserver_port}",
                        'role'       => 'pod',
                        'tls_config' => {
                            'insecure_skip_verify' => true,
                            'cert_file'            => $cert_pub,
                            'key_file'             => $cert_priv,
                        },
                    },
                ],
                'relabel_configs'       => [
                    {
                        'action'        => 'keep',
                        'regex'         => 'ingress-nginx',
                        'source_labels' => ['__meta_kubernetes_pod_label_app_kubernetes_io_name'],
                    },
                    {
                        'action' => 'labelmap',
                        'regex'  => '__meta_kubernetes_pod_label_(.+)',
                    },
                    {
                        'target_label' => '__address__',
                        'replacement'  => "${new_k8s_apiserver_fqdn}:${new_k8s_apiserver_port}",
                    },
                    {
                        'source_labels' => ['__meta_kubernetes_pod_name'],
                        'regex'         => '(ingress-nginx-gen2-controller-[a-zA-Z0-9]+-[a-zA-Z0-9]+)',
                        'target_label'  => '__metrics_path__',
                        # lint:ignore:single_quote_string_with_variables
                        # PORT is not arbitrary! the pod is listening on that one
                        'replacement'   => '/api/v1/namespaces/ingress-nginx-gen2/pods/${1}:10254/proxy/metrics',
                        # lint:endignore
                    },
                ]
            },
            {
                'job_name'              => 'new-k8s-api',
                'scheme'                => 'https',
                'tls_config'            => {
                    'insecure_skip_verify' => true,
                    'cert_file'            => $cert_pub,
                    'key_file'             => $cert_priv,
                },
                'kubernetes_sd_configs' => [
                    {
                        'api_server' => "https://${new_k8s_apiserver_fqdn}:${new_k8s_apiserver_port}",
                        'role'       => 'endpoints',
                        'tls_config' => {
                            'insecure_skip_verify' => true,
                            'cert_file'            => $cert_pub,
                            'key_file'             => $cert_priv,
                        },
                    },
                ],
                'relabel_configs'       => [
                    {
                        'action' => 'labelmap',
                        'regex'  => '__meta_kubernetes_node_label_(.+)',
                    },
                    {
                        'target_label' => '__address__',
                        'replacement'  => "${new_k8s_apiserver_fqdn}:${new_k8s_apiserver_port}",
                    },
                    {
                        'source_labels' => ['__meta_kubernetes_namespace',
                                            '__meta_kubernetes_service_name',
                                            '__meta_kubernetes_endpoint_port_name'],
                        'regex'         => 'default;kubernetes;https',
                        'action'        => 'keep',
                    },
                ]
            },
            {
                'job_name'       => 'new-k8s-haproxy',
                'scheme'         => 'http',
                'static_configs' => [
                    {
                        'targets' => ["${new_k8s_apiserver_fqdn}:9901"],
                    },
                ],
            },
            {
                'job_name'       => 'frontproxy-nginx',
                'scheme'         => 'http',
                'static_configs' => [
                    {
                        'targets' => map($proxies) |$element| { $value = "${element}:9113" },
                    },
                ],
            },
            {
                'job_name'              => 'new-k8s-kube-state-metrics',
                'scheme'                => 'https',
                'tls_config'            => {
                    'insecure_skip_verify' => true,
                    'cert_file'            => $cert_pub,
                    'key_file'             => $cert_priv,
                },
                'kubernetes_sd_configs' => [
                    {
                        'api_server' => "https://${new_k8s_apiserver_fqdn}:${new_k8s_apiserver_port}",
                        'role'       => 'pod',
                        'tls_config' => {
                            'insecure_skip_verify' => true,
                            'cert_file'            => $cert_pub,
                            'key_file'             => $cert_priv,
                        },
                    },
                ],
                'relabel_configs'       => [
                    {
                        'action' => 'labelmap',
                        'regex'  => '__meta_kubernetes_node_label_(.+)',
                    },
                    {
                        'target_label' => '__address__',
                        'replacement'  => "${new_k8s_apiserver_fqdn}:${new_k8s_apiserver_port}",
                    },
                    {
                        'target_label' => '__metrics_path__',
                        # this service is not an arbitrary name; it was created
                        # inside the k8s cluster with that specific name
                        'replacement'  => '/api/v1/namespaces/metrics/services/kube-state-metrics/proxy/metrics',
                    },
                ]
            },
            {
                'job_name'              => 'new-k8s-cadvisor',
                'scheme'                => 'https',
                'scrape_interval'       => '4m',
                'scrape_timeout'        => '60s',
                'tls_config'            => {
                    'insecure_skip_verify' => true,
                    'cert_file'            => $cert_pub,
                    'key_file'             => $cert_priv,
                },
                'kubernetes_sd_configs' => [
                    {
                        'api_server' => "https://${new_k8s_apiserver_fqdn}:${new_k8s_apiserver_port}",
                        'role'       => 'pod',
                        'tls_config' => {
                            'insecure_skip_verify' => true,
                            'cert_file'            => $cert_pub,
                            'key_file'             => $cert_priv,
                        },
                    },
                ],
                'relabel_configs'       => [
                    {
                        'action'        => 'keep',
                        'regex'         => 'cadvisor',
                        'source_labels' => ['__meta_kubernetes_pod_label_app'],
                    },
                    {
                        'action' => 'labelmap',
                        'regex'  => '__meta_kubernetes_pod_label_(.+)',
                    },
                    {
                        'target_label' => '__address__',
                        'replacement'  => "${new_k8s_apiserver_fqdn}:${new_k8s_apiserver_port}",
                    },
                    {
                        'source_labels' => ['__meta_kubernetes_pod_name'],
                        'regex'         => '(cadvisor-[a-zA-Z0-9]+)',
                        'target_label'  => '__metrics_path__',
                        # lint:ignore:single_quote_string_with_variables
                        'replacement'   => '/api/v1/namespaces/metrics/pods/${1}/proxy/metrics',
                        # lint:endignore
                    },
                ]
            },
            {
                'job_name'             => 'paws-node',
                'openstack_sd_configs' => [
                    {
                        'role'              => 'instance',
                        'region'            => 'eqiad1-r',
                        'identity_endpoint' => "http://${keystone_api_fqdn}:5000/v3",
                        'username'          => $observer_user,
                        'password'          => $observer_password,
                        'domain_name'       => 'default',
                        'project_name'      => 'paws',
                        'all_tenants'       => false,
                        'refresh_interval'  => '5m',
                        'port'              => 9100,
                    }
                ],
                'relabel_configs'      => [
                    {
                        'source_labels' => ['__meta_openstack_project_id'],
                        'replacement'   => 'paws',
                        'target_label'  => 'project',
                    },
                    {
                        'source_labels' => ['job'],
                        'replacement'   => 'node',
                        'target_label'  => 'job',
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
            },
            {
                'job_name'              => 'paws-k8s-nodes',
                'scheme'                => 'https',
                'tls_config'            => {
                    'insecure_skip_verify' => true,
                    'cert_file'            => $paws_cert_pub,
                    'key_file'             => $paws_cert_priv,
                },
                'kubernetes_sd_configs' => [
                    {
                        'api_server' => "https://${paws_apiserver_fqdn}:${paws_apiserver_port}",
                        'role'       => 'node',
                        'tls_config' => {
                            'insecure_skip_verify' => true,
                            'cert_file'            => $paws_cert_pub,
                            'key_file'             => $paws_cert_priv,
                        },
                    },
                ],
                'relabel_configs'       => [
                    {
                        'action' => 'labelmap',
                        'regex'  => '__meta_kubernetes_node_label_(.+)',
                    },
                    {
                        'target_label' => '__address__',
                        'replacement'  => "${paws_apiserver_fqdn}:${paws_apiserver_port}",
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
            {
                'job_name'              => 'paws-ingress-nginx',
                'scheme'                => 'https',
                'tls_config'            => {
                    'insecure_skip_verify' => true,
                    'cert_file'            => $paws_cert_pub,
                    'key_file'             => $paws_cert_priv,
                },
                'kubernetes_sd_configs' => [
                    {
                        'api_server' => "https://${paws_apiserver_fqdn}:${paws_apiserver_port}",
                        'role'       => 'pod',
                        'tls_config' => {
                            'insecure_skip_verify' => true,
                            'cert_file'            => $paws_cert_pub,
                            'key_file'             => $paws_cert_priv,
                        },
                    },
                ],
                'relabel_configs'       => [
                    {
                        'action'        => 'keep',
                        'regex'         => 'ingress-nginx',
                        'source_labels' => ['__meta_kubernetes_pod_label_app_kubernetes_io_name'],
                    },
                    {
                        'action' => 'labelmap',
                        'regex'  => '__meta_kubernetes_pod_label_(.+)',
                    },
                    {
                        'target_label' => '__address__',
                        'replacement'  => "${paws_apiserver_fqdn}:${paws_apiserver_port}",
                    },
                    {
                        'source_labels' => ['__meta_kubernetes_pod_name'],
                        'regex'         => '(ingress-nginx-gen2-controller-[a-zA-Z0-9]+-[a-zA-Z0-9]+)',
                        'target_label'  => '__metrics_path__',
                        # lint:ignore:single_quote_string_with_variables
                        # PORT is not arbitrary! the pod is listening on that one
                        'replacement'   => '/api/v1/namespaces/ingress-nginx-gen2/pods/${1}:10254/proxy/metrics',
                        # lint:endignore
                    },
                ]
            },
            {
                'job_name'              => 'paws-api',
                'scheme'                => 'https',
                'tls_config'            => {
                    'insecure_skip_verify' => true,
                    'cert_file'            => $paws_cert_pub,
                    'key_file'             => $paws_cert_priv,
                },
                'kubernetes_sd_configs' => [
                    {
                        'api_server' => "https://${paws_apiserver_fqdn}:${paws_apiserver_port}",
                        'role'       => 'endpoints',
                        'tls_config' => {
                            'insecure_skip_verify' => true,
                            'cert_file'            => $paws_cert_pub,
                            'key_file'             => $paws_cert_priv,
                        },
                    },
                ],
                'relabel_configs'       => [
                    {
                        'action' => 'labelmap',
                        'regex'  => '__meta_kubernetes_node_label_(.+)',
                    },
                    {
                        'target_label' => '__address__',
                        'replacement'  => "${paws_apiserver_fqdn}:${paws_apiserver_port}",
                    },
                    {
                        'source_labels' => ['__meta_kubernetes_namespace',
                                            '__meta_kubernetes_service_name',
                                            '__meta_kubernetes_endpoint_port_name'],
                        'regex'         => 'default;kubernetes;https',
                        'action'        => 'keep',
                    },
                ]
            },
            {
                'job_name'       => 'paws-haproxy',
                'scheme'         => 'http',
                'static_configs' => [
                    {
                        'targets' => ["${paws_apiserver_fqdn}:9901"],
                    },
                ],
            },
            {
                'job_name'              => 'paws-kube-state-metrics',
                'scheme'                => 'https',
                'tls_config'            => {
                    'insecure_skip_verify' => true,
                    'cert_file'            => $paws_cert_pub,
                    'key_file'             => $paws_cert_priv,
                },
                'kubernetes_sd_configs' => [
                    {
                        'api_server' => "https://${paws_apiserver_fqdn}:${paws_apiserver_port}",
                        'role'       => 'pod',
                        'tls_config' => {
                            'insecure_skip_verify' => true,
                            'cert_file'            => $paws_cert_pub,
                            'key_file'             => $paws_cert_priv,
                        },
                    },
                ],
                'relabel_configs'       => [
                    {
                        'action' => 'labelmap',
                        'regex'  => '__meta_kubernetes_node_label_(.+)',
                    },
                    {
                        'target_label' => '__address__',
                        'replacement'  => "${paws_apiserver_fqdn}:${paws_apiserver_port}",
                    },
                    {
                        'target_label' => '__metrics_path__',
                        # this service is not an arbitrary name; it was created
                        # inside the k8s cluster with that specific name
                        'replacement'  => '/api/v1/namespaces/metrics/services/kube-state-metrics/proxy/metrics',
                    },
                ]
            },
            {
                'job_name'              => 'paws-cadvisor',
                'scheme'                => 'https',
                'tls_config'            => {
                    'insecure_skip_verify' => true,
                    'cert_file'            => $paws_cert_pub,
                    'key_file'             => $paws_cert_priv,
                },
                'kubernetes_sd_configs' => [
                    {
                        'api_server' => "https://${paws_apiserver_fqdn}:${paws_apiserver_port}",
                        'role'       => 'pod',
                        'tls_config' => {
                            'insecure_skip_verify' => true,
                            'cert_file'            => $paws_cert_pub,
                            'key_file'             => $paws_cert_priv,
                        },
                    },
                ],
                'relabel_configs'       => [
                    {
                        'action'        => 'keep',
                        'regex'         => 'cadvisor',
                        'source_labels' => ['__meta_kubernetes_pod_label_app'],
                    },
                    {
                        'action' => 'labelmap',
                        'regex'  => '__meta_kubernetes_pod_label_(.+)',
                    },
                    {
                        'target_label' => '__address__',
                        'replacement'  => "${paws_apiserver_fqdn}:${paws_apiserver_port}",
                    },
                    {
                        'source_labels' => ['__meta_kubernetes_pod_name'],
                        'regex'         => '(cadvisor-[a-zA-Z0-9]+)',
                        'target_label'  => '__metrics_path__',
                        # lint:ignore:single_quote_string_with_variables
                        'replacement'   => '/api/v1/namespaces/metrics/pods/${1}/proxy/metrics',
                        # lint:endignore
                    },
                ]
            },
            {
                'job_name'       => 'paws-jupyterhub',
                'scheme'         => 'https',
                'metrics_path'   => '/hub/metrics',
                'static_configs' => [
                    {
                        'targets' => ['hub.paws.wmcloud.org'],
                    },
                ],
            },
            {
                'job_name'       => 'tools-email',
                'scheme'         => 'http',
                'static_configs' => [
                    {
                        # this is using mtail exim which listens on 3903 by default
                        'targets' => ["${email_server}:3903"],
                    },
                ],
            },
        ]
    }

    prometheus::web { 'tools':
        proxy_pass => 'http://localhost:9902/tools',
    }

    file { "${targets_path}/toolsdb-mariadb.yml":
      content => ordered_yaml([{
        'targets' => ['clouddb1001.clouddb-services.eqiad.wmflabs:9104',
                      'clouddb1002.clouddb-services.eqiad.wmflabs:9104',
            ]
        }]),
    }

    file { "${targets_path}/toolsdb-node.yml":
      content => ordered_yaml([{
        'targets' => ['clouddb1001.clouddb-services.eqiad.wmflabs:9100',
                      'clouddb1002.clouddb-services.eqiad.wmflabs:9100',
            ]
        }]),
    }

    cron { 'prometheus_tools_project_targets':
        ensure  => present,
        command => "/usr/local/bin/prometheus-labs-targets > ${targets_path}/node_project.$$ && mv ${targets_path}/node_project.$$ ${targets_path}/node_project.yml",
        minute  => '*/10',
        hour    => '*',
        user    => 'prometheus',
    }

    cron { 'prometheus_paws_k8s_etcd_targets':
        ensure  => present,
        command => "/usr/local/bin/prometheus-labs-targets --project paws --port 2381 --prefix paws-k8s-control- > ${targets_path}/etcd_paws.$$ && mv ${targets_path}/etcd_paws.$$ ${targets_path}/etcd_paws.yml",
        minute  => '*/10',
        hour    => '*',
        user    => 'prometheus',
    }

    cron { 'prometheus_tools_project_ssh_targets':
        ensure  => present,
        command => "/usr/local/bin/prometheus-labs-targets --port 22 > ${targets_path}/ssh_banner.$$ && mv ${targets_path}/ssh_banner.$$ ${targets_path}/ssh_banner.yml",
        minute  => '*/10',
        hour    => '*',
        user    => 'prometheus',
    }

    cron { 'prometheus_tools_k8s_etcd_targets':
        ensure  => present,
        command => "/usr/local/bin/prometheus-labs-targets --port 9051 --prefix tools-k8s-etcd- > ${targets_path}/etcd_k8s.$$ && mv ${targets_path}/etcd_k8s.$$ ${targets_path}/etcd_k8s.yml",
        minute  => '*/10',
        hour    => '*',
        user    => 'prometheus',
    }
}
