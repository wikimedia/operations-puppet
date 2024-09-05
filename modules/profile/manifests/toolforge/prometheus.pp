# This profile provides both project-wide host discovery/monitoring (via cron
# prometheus-labs-targets) and kubernetes discovery/monitoring via Prometheus'
# native k8s support.
# @param allow_pages boolean to disable paging alerts on non-production deployments
class profile::toolforge::prometheus (
    Stdlib::Fqdn               $web_domain                         = lookup('profile::toolforge::web_domain', {default_value => 'toolforge.org'}),
    Stdlib::Fqdn               $k8s_apiserver_fqdn                 = lookup('profile::toolforge::k8s::apiserver_fqdn', {default_value => 'k8s.tools.eqiad1.wikimedia.cloud'}),
    Stdlib::Port               $k8s_apiserver_port                 = lookup('profile::toolforge::k8s::apiserver_port', {default_value => 6443}),
    String                     $region                             = lookup('profile::openstack::eqiad1::region'),
    Stdlib::Fqdn               $keystone_api_fqdn                  = lookup('profile::openstack::eqiad1::keystone_api_fqdn'),
    String                     $observer_password                  = lookup('profile::openstack::eqiad1::observer_password'),
    String                     $observer_user                      = lookup('profile::openstack::base::observer_user'),
    Boolean                    $allow_pages                        = lookup('profile::toolforge::prometheus::allow_pages', {default_value => false}),
    Optional[Stdlib::Datasize] $storage_retention_size             = lookup('profile::toolforge::prometheus::storage_retention_size',   {default_value => undef}),
    Array[Stdlib::HTTPUrl]     $probes_pingthing_http_check_urls   = lookup('profile::toolforge::prometheus::probes_pingthing_http_check_urls', { 'default_value' => [] }),
) {
    # Bullseye VMs (currently only in toolsbeta) have their storage mounted via Cinder
    if debian::codename::le('buster') {
        require ::profile::labs::lvm::srv
    }

    class { '::prometheus::blackbox_exporter': }

    if debian::codename::ge('bullseye') {
        # Checks for custom probes, defined in puppet
        prometheus::blackbox::import_checks { 'tools':
            prometheus_instance => 'tools',
            site                => $::site,
        }
    }

    $targets_path = '/srv/prometheus/tools/targets'

    class { 'httpd':
        modules => [
            'proxy',
            'proxy_http',
            'rewrite',
        ],
    }

    # the certs are used by prometheus to auth to the k8s API and are
    # generated in the k8s control nodes using the wmcs-k8s-get-cert script
    $toolforge_certname = $::wmcs_project ? {
        'tools'     => 'toolforge-k8s-prometheus',
        'toolsbeta' => 'toolsbeta-k8s-prometheus',
    }

    $instance_prefix = $::wmcs_project
    $instance_prefix_k8s = $::wmcs_project ? {
        'toolsbeta' => 'toolsbeta-test',
        default     => $::wmcs_project,
    }

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

    file {"${targets_path}/probes_pingthing_http_check_urls.yaml":
        backup  => false,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => to_yaml([{'targets' => $probes_pingthing_http_check_urls}]),
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
            instance_filter => "${instance_prefix}-proxy-\\d+",
        },
        {
            name            => 'frontproxy-redis',
            port            => 9121,
            instance_filter => "${instance_prefix}-proxy-\\d+",
        },
        {
            name            => 'haproxy',
            port            => 9901,
            instance_filter => "${instance_prefix_k8s}-k8s-haproxy-\\d+",
        },
        {
            name            => 'exim',
            port            => 3903,
            instance_filter => "${instance_prefix}-mail-\\d+",
        },
        {
            name            => 'k8s-etcd',
            port            => 9051,
            instance_filter => "${instance_prefix_k8s}-k8s-etcd-\\d+",
        },
        {
            name            => 'k8s-apiserver',
            port            => 6443,
            instance_filter => "${instance_prefix_k8s}-k8s-control-\\d+",
            extra_config    => {
                scheme     => 'https',
                tls_config => $k8s_tls_config,
            },
        },
        {
            name            => 'harbor',
            port            => 9090,
            instance_filter => "${instance_prefix}-harbor-\\d+",
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
                    'project_name'      => pick($job['project'], $::wmcs_project),
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

    # Relabel configuration to support for targets in the following forms to
    # keep 'instance' label readable:
    # - bare target (i.e. no @) -> copy unmodified to 'instance'
    # - target in the form of foo@bar -> use foo as 'instance' and 'bar' as target

    # This allows targets in the form of e.g.:
    # - target: 'foo:443@https://foo.discovery.wmnet:443/path'
    # will become:
    # - instance: 'foo:443' (for usage as metric label)
    # - target: 'https://foo.discovery.wmnet:443/path' (full url for blackbox to probe)

    # Note that all regex here are implicitly anchored (^<regex>$)
    $probes_relabel_configs = [
        {
            'source_labels' => ['__address__'],
            'regex'         => '([^@]+)',
            'target_label'  => 'instance',
        },
        {
            'source_labels' => ['__address__'],
            'regex'         => '([^@]+)',
            'target_label'  => '__param_target',
        },
        {
            'source_labels' => ['__address__'],
            'regex'         => '(.+)@(.+)',
            'target_label'  => 'instance',
            'replacement'   => '${1}', # lint:ignore:single_quote_string_with_variables
        },
        {
            'source_labels' => ['__address__'],
            'regex'         => '(.+)@(.+)',
            'target_label'  => '__param_target',
            'replacement'   => '${2}', # lint:ignore:single_quote_string_with_variables
        },
        {
            'source_labels' => ['module'],
            'target_label'  => '__param_module',
        },
        {
            'target_label' => '__address__',
            'replacement'  => '127.0.0.1:9115',
        },
    ]

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
        {
            'job_name'        => 'probes/custom',
            'metrics_path'    => '/probe',
            'scrape_interval' => '30s',
            # blackbox-exporter will use the lower value between this and
            # the module configured timeout. We want the latter, therefore
            # set a high timeout here (but no longer than scrape_interval)
            'scrape_timeout'  => '30s',
            'file_sd_configs' => [
              { 'files' => [ "${targets_path}/probes-custom_*.yaml" ] }
            ],
            'relabel_configs' => $probes_relabel_configs,
        },
        {
            'job_name'        => 'probes/pingthing',
            'metrics_path'    => '/probe',
            'params'          => {
                'module' => [ 'http_connect_23xx' ],
            },
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/probes_pingthing_http_check_urls.yaml" ] }
            ],
            'relabel_configs'=> [
                {
                    'source_labels' => ['__address__'],
                    'regex'         => '(.*)',
                    'target_label'  => 'url',
                },
                {
                    'source_labels' => ['__address__'],
                    'regex'         => '([^@]+)',
                    'target_label'  => '__param_target',
                },
                {
                    'source_labels' => ['__address__'],
                    'regex'         => '(.+)@(.+)',
                    'target_label'  => '__param_target',
                    'replacement'   => '${2}', # lint:ignore:single_quote_string_with_variables
                },
                {
                    'source_labels' => ['module'],
                    'target_label'  => '__param_module',
                },
                {
                    'target_label' => '__address__',
                    'replacement'  => '127.0.0.1:9115',
                },
            ],
        },
        {
            'job_name' => 'pint',
            'scheme'   => 'http',
            'static_configs' => [
                { 'targets' => [ 'localhost:9123' ] },
            ],
        },
    ]

    $kubernetes_pod_jobs = [
        {
            name      => 'k8s-cert-manager',
            namespace => 'cert-manager',
            pod_name  => 'cert-manager-[a-zA-Z0-9]+-[a-zA-Z0-9]+',
            port      => 9402,
        },
        {
            name      => 'k8s-cert-manager-reloader',
            namespace => 'cert-manager',
            pod_name  => 'reloader-reloader-[a-zA-Z0-9]+-[a-zA-Z0-9]+',
            port      => 9090,
        },
        {
            name      => 'k8s-coredns',
            namespace => 'kube-system',
            pod_name  => 'coredns-[a-zA-Z0-9]+-[a-zA-Z0-9]+',
            port      => 9153,
        },
        {
            name                  => 'k8s-ingress-nginx',
            namespace             => 'ingress-nginx-gen2',
            pod_name              => 'ingress-nginx-gen2-controller-[a-zA-Z0-9]+-[a-zA-Z0-9]+',
            port                  => 10254,
            extra_config          => {
                scrape_interval => '4m',
                scrape_timeout  => '60s',
                metric_relabel_configs => [
                    # keeping only the series we actually use
                    #   see https://phabricator.wikimedia.org/T370143
                    {
                        'action'        => 'keep',
                        'source_labels' => ['__name__'],
                        'regex'         => '.*(requests|process_connections).*',
                    },
                ],
            },
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
            name      => 'k8s-maintain-kubeusers',
            namespace => 'maintain-kubeusers',
            pod_name  => 'maintain-kubeusers-[a-zA-Z0-9]+-[a-zA-Z0-9]+',
            port      => 9000,
        },
        {
            name      => 'k8s-kube-state-metrics',
            namespace => 'metrics',
            pod_name  => 'kube-state-metrics-[a-zA-Z0-9]+-[a-zA-Z0-9]+',
            port      => 8080,
        },
        {
            name      => 'jobs-api',
            namespace => 'jobs-api',
            pod_name  => 'jobs-api-[a-zA-Z0-9]+-[a-zA-Z0-9]+',
            port      => 9000,
        },
        {
            name      => 'tekton-pipelines-controller',
            namespace => 'tekton-pipelines',
            pod_name  => 'tekton-pipelines-controller-[a-zA-Z0-9]+-[a-zA-Z0-9]+',
            port      => 9090,
        },
        {
            name      => 'builds-api',
            namespace => 'builds-api',
            pod_name  => 'builds-api-[a-zA-Z0-9]+-[a-zA-Z0-9]+',
            port      => 9000,
        },
        {
            name      => 'envvars-api',
            namespace => 'envvars-api',
            pod_name  => 'envvars-api-[a-zA-Z0-9]+-[a-zA-Z0-9]+',
            port      => 9000,
        },
        {
            name      => 'kyverno',
            namespace => 'kyverno',
            pod_name  => 'kyverno-.*controller.*',
            port      => 8000,
        },
        # This is for Toolforge infrastructure only. Do not add any
        # user workloads here.
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
                    'action'      => 'labelmap',
                    'regex'       => '__meta_kubernetes_pod_name',
                    'replacement' => 'pod_name',
                },
                {
                    'action'      => 'labelmap',
                    'regex'       => '__meta_kubernetes_pod_label_(.+)',
                    'replacement' => 'pod_label_$1', # lint:ignore:single_quote_string_with_variables
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

    class { 'alerts::deploy::prometheus':
        git_source => 'gitlab',
        git_repo   => 'repos/cloud/toolforge/alerts',
        git_branch => 'main',
        instances  => ["project-${::wmcs_project}"],
    }

    if $allow_pages {
        $page_filter = undef
    } else {
        # Rewrite pages as criticals on non-production deployments.
        $page_filter = {
            'action'       => 'replace',
            'target_label' => 'severity',
            'regex'        => 'page',
            'replacement'  => 'critical',
        }
    }

    prometheus::server { 'tools':
        listen_address                 => '127.0.0.1:9902',
        external_url                   => "https://prometheus.svc.${web_domain}/tools",
        storage_retention_size         => $storage_retention_size,
        scrape_configs_extra           => $jobs,
        alertmanager_discovery_extra   => $alertmanager_discovery_extra,
        rule_files_extra               => ["/srv/alerts/project-${::wmcs_project}/*.yaml"],
        alerting_relabel_configs_extra => [
            { 'target_label' => 'project', 'replacement' => $::wmcs_project, 'action' => 'replace' },
            { 'target_label' => 'team',    'replacement' => 'wmcs',          'action' => 'replace' },
            $page_filter,
        ].filter |$it| { $it != undef },
    }

    prometheus::rule { 'rules_kubernetes.yml':
        instance => 'tools',
        source   => 'puppet:///modules/profile/toolforge/prometheus/rules_kubernetes.yml',
    }

    prometheus::web { 'tools':
        proxy_pass => 'http://localhost:9902/tools',
        homepage   => true,
    }

    prometheus::pint::source { 'tools':
        port       => 9902,
        all_alerts => true,
    }
}
