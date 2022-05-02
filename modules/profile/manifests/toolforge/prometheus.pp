# This profile provides both project-wide host discovery/monitoring (via cron
# prometheus-labs-targets) and kubernetes discovery/monitoring via Prometheus'
# native k8s support.

class profile::toolforge::prometheus (
    Stdlib::Fqdn               $k8s_apiserver_fqdn     = lookup('profile::toolforge::k8s::apiserver_fqdn', {default_value => 'k8s.tools.eqiad1.wikimedia.cloud'}),
    Stdlib::Port               $k8s_apiserver_port     = lookup('profile::toolforge::k8s::apiserver_port', {default_value => 6443}),
    String                     $region                 = lookup('profile::openstack::eqiad1::region'),
    Stdlib::Fqdn               $keystone_api_fqdn      = lookup('profile::openstack::eqiad1::keystone_api_fqdn'),
    String                     $observer_password      = lookup('profile::openstack::eqiad1::observer_password'),
    String                     $observer_user          = lookup('profile::openstack::base::observer_user'),
    Optional[Stdlib::Datasize] $storage_retention_size = lookup('profile::toolforge::prometheus::storage_retention_size',   {default_value => undef}),
) {
    require ::profile::labs::lvm::srv
    include ::profile::prometheus::blackbox_exporter

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

    $k8s_tls_config = {
        'insecure_skip_verify' => true,
        'cert_file'            => $cert_pub,
        'key_file'             => $cert_priv,
    }

    $openstack_jobs = [
        {
            name => 'node-exporter',
            port => 9100,
        },
        {
            name                  => 'ssh-banner',
            port                  => 22,
            extra_relabel_configs => [
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
            ],
            extra_config          => {
                metrics_path    => '/probe',
                params          => {
                    module => ['ssh_banner'],
                },
            },
        },
        {
            name            => 'frontproxy-nginx',
            port            => 9113,
            instance_filter => 'tools-proxy-\\d+',
        },
        {
            name            => 'haproxy',
            port            => 9901,
            instance_filter => 'tools-k8s-haproxy-\\d+',
        },
        {
            name            => 'exim',
            port            => 3903,
            instance_filter => 'tools-mail-\\d+',
        },
        {
            name            => 'k8s-etcd',
            port            => 9051,
            instance_filter => 'tools-k8s-etcd-\\d+',
        },
        {
            name            => 'k8s-apiserver',
            port            => 6443,
            instance_filter => 'tools-k8s-control-\\d+',
            extra_config    => {
                scheme     => 'https',
                tls_config => $k8s_tls_config,
            },
        },
        {
            name            => 'toolsdb-node',
            port            => 9100,
            project         => 'clouddb-services',
            instance_filter => 'clouddb100[12]',
        },
        {
            name            => 'toolsdb-mariadb',
            port            => 9104,
            project         => 'clouddb-services',
            instance_filter => 'clouddb100[12]',
        },
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
                    'project_name'      => pick($job['project'], $::labsproject, 'fallback-for-ci'),
                    'all_tenants'       => false,
                    'refresh_interval'  => '5m',
                    'port'              => $job['port'],
                }
            ],
            'relabel_configs'      => $relabel_configs + pick($job['extra_relabel_configs'], [])
        }

        deep_merge(
            $result,
            pick($job['extra_config'], {})
        )
    }

    $manual_jobs = [
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
            name         => 'k8s-cadvisor',
            namespace    => 'metrics',
            pod_name     => 'cadvisor-[a-zA-Z0-9]+',
            port         => 8080,
            extra_config => {
                scrape_interval => '4m',
                scrape_timeout  => '60s',
            },
        },
        {
            name      => 'k8s-kube-state-metrics',
            namespace => 'metrics',
            pod_name  => 'kube-state-metrics-[a-zA-Z0-9]+-[a-zA-Z0-9]+',
            port      => 8080,
        },
    ].map |Hash $job| {
        $result = {
            'job_name'              => $job['name'],
            'scheme'                => 'https',
            'tls_config'            => $k8s_tls_config,
            'kubernetes_sd_configs' => [
                {
                    'api_server' => "https://${k8s_apiserver_fqdn}:${k8s_apiserver_port}",
                    'role'       => 'pod',
                    'tls_config' => $k8s_tls_config,
                },
            ],
            'relabel_configs'       => [
                {
                    'action'        => 'keep',
                    'regex'         => $job['namespace'],
                    'source_labels' => ['__meta_kubernetes_namespace'],
                },
                {
                    'action'        => 'keep',
                    'regex'         => $job['pod_name'],
                    'source_labels' => ['__meta_kubernetes_pod_name'],
                },
                {
                    'action' => 'labelmap',
                    'regex'  => '__meta_kubernetes_pod_label_(.+)',
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

        deep_merge(
            $result,
            pick($job['extra_config'], {})
        )
    }

    $jobs = $openstack_jobs + $manual_jobs + $kubernetes_pod_jobs

    prometheus::server { 'tools':
        listen_address         => '127.0.0.1:9902',
        external_url           => 'https://tools-prometheus.wmflabs.org/tools',
        storage_retention_size => $storage_retention_size,
        scrape_configs_extra   => $jobs,
    }

    prometheus::web { 'tools':
        proxy_pass => 'http://localhost:9902/tools',
    }
}
