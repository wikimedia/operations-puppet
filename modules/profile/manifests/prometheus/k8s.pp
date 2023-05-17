# SPDX-License-Identifier: Apache-2.0
# Uses the prometheus module and generates the specific configuration
# needed for WMF production
#
class profile::prometheus::k8s (
    Hash                $k8s_clusters          = lookup('profile::prometheus::kubernetes::clusters'),
    Hash                $k8s_cluster_tokens    = lookup('profile::prometheus::kubernetes::cluster_tokens'),
    String              $replica_label         = lookup('prometheus::replica_label', { 'default_value' => 'unset' }),
    Boolean             $enable_thanos_upload  = lookup('profile::prometheus::enable_thanos_upload', { 'default_value' => false }),
    Optional[String]    $thanos_min_time       = lookup('profile::prometheus::thanos::min_time', { 'default_value' => undef }),
    Array[Stdlib::Host] $alertmanagers         = lookup('alertmanagers', {'default_value' => []}),
    String              $storage_retention     = lookup('prometheus::server::storage_retention', {'default_value' => '4032h'}),
    Integer             $max_chunks_to_persist = lookup('prometheus::server::max_chunks_to_persist', {'default_value' => 524288}),
    Integer             $memory_chunks         = lookup('prometheus::server::memory_chunks', {'default_value' => 1048576}),
    Boolean             $disable_compaction    = lookup('profile::prometheus::thanos::disable_compaction', { 'default_value' => false }),
){

    $real_k8s_clusters = deep_merge($k8s_clusters, $k8s_cluster_tokens)
    $enabled_k8s_clusters = $real_k8s_clusters.filter |String $k8s_cluster, Hash $value| {
        $value['enabled']
    }

    # Let's detect port duplications and fail early
    $l = length($enabled_k8s_clusters.keys())
    $p = length(unique($enabled_k8s_clusters.map |String $k, Hash $v| { $v['port'] }))
    if $l != $p {
        fail('Port duplication detected in k8s_clusters declaration')
    }

    $enabled_k8s_clusters.each |String $k8s_cluster, Hash $value| {
        $targets_path = "/srv/prometheus/${k8s_cluster}/targets"
        $bearer_token_file = "/srv/prometheus/${k8s_cluster}/k8s.token"
        $master_host = $value['master_host']
        $port = $value['port']
        $class_name = $value['class_name']
        $controller_class_name = $value['controller_class_name']
        $client_token = $value['client_token']

        $config_extra = {
            # All metrics will get an additional 'site' label when queried by
            # external systems (e.g. via federation)
            'external_labels' => {
                'site'       => $::site,
                'replica'    => $replica_label,
                'prometheus' => $k8s_cluster,
            },
        }
        # Configure scraping from k8s cluster with distinct jobs:
        # - k8s-api: api server metrics (each one, as returned by k8s)
        # - k8s-node: metrics from each node running k8s
        # See also:
        # * https://prometheus.io/docs/operating/configuration/#<kubernetes_sd_config>
        # * https://github.com/prometheus/prometheus/blob/master/documentation/examples/prometheus-kubernetes.yml
        $scrape_configs_extra = [
            {
                'job_name'              => 'k8s-api',
                'bearer_token_file'     => $bearer_token_file,
                'scheme'                => 'https',
                'tls_config' => {
                    'server_name' => $master_host,
                },
                'kubernetes_sd_configs' => [
                    {
                        'api_server'        => "https://${master_host}:6443",
                        'bearer_token_file' => $bearer_token_file,
                        'role'              => 'endpoints',
                    },
                ],
                # Scrape config for API servers, keep only endpoints for default/kubernetes to poll only
                # api servers
                'relabel_configs'       => [
                    {
                        'source_labels' => ['__meta_kubernetes_namespace',
                                            '__meta_kubernetes_service_name',
                                            '__meta_kubernetes_endpoint_port_name'],
                        'action'        => 'keep',
                        'regex'         => 'default;kubernetes;https',
                    },
                ],
            },
            {
                'job_name'              => 'k8s-node',
                'bearer_token_file'     => $bearer_token_file,
                'kubernetes_sd_configs' => [
                    {
                        'api_server'        => "https://${master_host}:6443",
                        'bearer_token_file' => $bearer_token_file,
                        'role'              => 'node',
                    },
                ],
                'relabel_configs'       => [
                    # Map kubernetes node labels to prometheus metric labels
                    {
                        'action' => 'labelmap',
                        'regex'  => '__meta_kubernetes_node_label_(.+)',
                    },
                    {
                        # Force read-only API for nodes. This listens on port 10255
                        # so rewrite the __address__ label to use that port. It's
                        # also HTTP, not HTTPS
                        'action'        => 'replace',  # Redundant but clearer
                        'source_labels' => ['__address__'],
                        'target_label'  => '__address__',
                        'regex'         => '([\d\.]+):(\d+)',
                        'replacement'   => "\${1}:10255",
                    },
                ]
            },
            {
                'job_name'              => 'k8s-node-cadvisor',
                'bearer_token_file'     => $bearer_token_file,
                'metrics_path'          => '/metrics/cadvisor',
                'kubernetes_sd_configs' => [
                    {
                        'api_server'        => "https://${master_host}:6443",
                        'bearer_token_file' => $bearer_token_file,
                        'role'              => 'node',
                    },
                ],
                'relabel_configs'       => [
                    # Map kubernetes node labels to prometheus metric labels
                    {
                        'action' => 'labelmap',
                        'regex'  => '__meta_kubernetes_node_label_(.+)',
                    },
                    {
                        # Force read-only API for nodes. This listens on port 10255
                        # so rewrite the __address__ label to use that port. It's
                        # also HTTP, not HTTPS
                        'action'        => 'replace',  # Redundant but clearer
                        'source_labels' => ['__address__'],
                        'target_label'  => '__address__',
                        'regex'         => '([\d\.]+):(\d+)',
                        'replacement'   => "\${1}:10255",
                    },
                ]
            },
            {
                'job_name'              => 'k8s-node-proxy',
                'bearer_token_file'     => $bearer_token_file,
                'kubernetes_sd_configs' => [
                    {
                        'api_server'        => "https://${master_host}:6443",
                        'bearer_token_file' => $bearer_token_file,
                        'role'              => 'node',
                    },
                ],
                'relabel_configs'       => [
                    # Map kubernetes node labels to prometheus metric labels
                    {
                        'action' => 'labelmap',
                        'regex'  => '__meta_kubernetes_node_label_(.+)',
                    },
                    {
                        # Force read-only API for talking to kubeproxy. Listens on
                        # port 10249 so rewrite the __address__ label to use that
                        # port. It's also HTTP, not HTTPS
                        'action'        => 'replace',  # Redundant but clearer
                        'source_labels' => ['__address__'],
                        'target_label'  => '__address__',
                        'regex'         => '([\d\.]+):(\d+)',
                        'replacement'   => "\${1}:10249",
                    },
                ]
            },
            {
                'job_name'              => 'k8s-pods',
                'bearer_token_file'     => $bearer_token_file,
                # Note: We dont verify the cert on purpose. Issues IP SAN based
                # certs for all pods is impossible
                'tls_config'            => {
                    insecure_skip_verify =>  true,
                },
                'kubernetes_sd_configs' => [
                    {
                        'api_server'        => "https://${master_host}:6443",
                        'bearer_token_file' => $bearer_token_file,
                        'role'              => 'pod',
                    },
                ],
                'relabel_configs' => [
                    {
                        'action'        => 'keep',
                        'source_labels' => ['__meta_kubernetes_pod_annotation_prometheus_io_scrape'],
                        'regex'         => true,
                    },
                    {
                        'action'        => 'replace',
                        'source_labels' => ['__meta_kubernetes_pod_annotation_prometheus_io_path'],
                        'target_label'  => '__metrics_path__',
                        'regex'         => '(.+)',
                    },
                    {
                        'action'        => 'replace',
                        'source_labels' => ['__meta_kubernetes_pod_annotation_prometheus_io_scheme'],
                        'target_label'  => '__scheme__',
                        'regex'         => '(.+)',
                    },
                    # This instructs prometheus to only scrape a single port for
                    # a pod instead of the default behavior
                    #
                    # By default, the pod role discovers all pods and exposes
                    # their containers as targets. For each declared port of a
                    # container, a single target is generated. If a container
                    # has no specified ports, a port-free target per container
                    # is created for manually adding a port via relabeling. If
                    # no relabelling action is taken, port 80 is chosen.
                    {
                        'action'        => 'replace',
                        'source_labels' => ['__address__', '__meta_kubernetes_pod_annotation_prometheus_io_port'],
                        'regex'         => '([^:]+)(?::\d+)?;(\d+)',
                        'replacement'   => '$1:$2',
                        'target_label'  => '__address__',
                    },
                    {
                        'action'        => 'labelmap',
                        'regex'         => '__meta_kubernetes_pod_label_(.+)',
                    },
                    {
                        'action'        => 'replace',
                        'source_labels' => ['__meta_kubernetes_namespace'],
                        'target_label'  => 'kubernetes_namespace',
                    },
                    {
                        'action'        => 'replace',
                        'source_labels' => ['__meta_kubernetes_pod_name'],
                        'target_label'  => 'kubernetes_pod_name',
                    },
                ]
            },
            {
                'job_name'              => 'k8s-pods-metrics',
                'bearer_token_file'     => $bearer_token_file,
                # Note: We dont verify the cert on purpose. Issues IP SAN based
                # certs for all pods is impossible
                'tls_config'            => {
                    insecure_skip_verify =>  true,
                },
                'kubernetes_sd_configs' => [
                    {
                        'api_server'        => "https://${master_host}:6443",
                        'bearer_token_file' => $bearer_token_file,
                        'role'              => 'pod',
                    },
                ],
                'relabel_configs' => [
                    # We only scrape ports that have a name ending in -metrics, and have
                    # prometheus.io/scrape_by_name: true
                    # You can still control the path of the metrics and the url scheme using
                    # prometheus.io/path and prometheus.io/scheme as annotations.
                    #
                    {
                        'action'        => 'keep',
                        'source_labels' => ['__meta_kubernetes_pod_container_port_name'],
                        'regex'         => '.*-metrics',
                    },
                    {
                        'action'        => 'keep',
                        'source_labels' => ['__meta_kubernetes_pod_annotation_prometheus_io_scrape_by_name'],
                        'regex'         => true,
                    },
                    {
                        'action'        => 'replace',
                        'source_labels' => ['__meta_kubernetes_pod_annotation_prometheus_io_path'],
                        'target_label'  => '__metrics_path__',
                        'regex'         => '(.+)',
                    },
                    {
                        'action'        => 'replace',
                        'source_labels' => ['__meta_kubernetes_pod_annotation_prometheus_io_scheme'],
                        'target_label'  => '__scheme__',
                        'regex'         => '(.+)',
                    },
                    {
                        'action'        => 'labelmap',
                        'regex'         => '__meta_kubernetes_pod_label_(.+)',
                    },
                    {
                        'action'        => 'replace',
                        'source_labels' => ['__meta_kubernetes_namespace'],
                        'target_label'  => 'kubernetes_namespace',
                    },
                    {
                        'action'        => 'replace',
                        'source_labels' => ['__meta_kubernetes_pod_name'],
                        'target_label'  => 'kubernetes_pod_name',
                    },
                    {
                        'action'        => 'replace',
                        'source_labels' => ['job'],
                        'regex'         => '.*',
                        'replacement'   => 'k8s-pods',
                        'target_label'  => 'job'
                    },
                ]
            },
            {
                'job_name'              => 'k8s-pods-tls',
                'bearer_token_file'     => $bearer_token_file,
                'metrics_path'          => '/stats/prometheus',
                'scheme'                => 'http',
                'kubernetes_sd_configs' => [
                    {
                        'api_server'        => "https://${master_host}:6443",
                        'bearer_token_file' => $bearer_token_file,
                        'role'              => 'pod',
                    },
                ],
                'metric_relabel_configs' => [
                    {   'source_labels' => ['__name__'],
                        'regex'         => '^envoy_(http_down|cluster_up)stream_(rq|cx).*$',
                        'action'        => 'keep'
                    },
                ],
                'relabel_configs' => [
                    {
                        'action'        => 'keep',
                        'source_labels' => ['__meta_kubernetes_pod_annotation_envoyproxy_io_scrape'],
                        'regex'         => true,
                    },
                    {
                        'action'        => 'drop',
                        'source_labels' => ['envoy_cluster_name'],
                        'regex'         => '^admin_interface$',
                    },
                    {
                        'action'        => 'replace',
                        'source_labels' => ['__address__', '__meta_kubernetes_pod_annotation_envoyproxy_io_port'],
                        'regex'         => '([^:]+)(?::\d+)?;(\d+)',
                        'replacement'   => '$1:$2',
                        'target_label'  => '__address__',
                    },
                    {
                        'action'        => 'labelmap',
                        'regex'         => '__meta_kubernetes_pod_label_(.+)',
                    },
                    {
                        'action'        => 'replace',
                        'source_labels' => ['__meta_kubernetes_namespace'],
                        'target_label'  => 'kubernetes_namespace',
                    },
                    {
                        'action'        => 'replace',
                        'source_labels' => ['__meta_kubernetes_pod_name'],
                        'target_label'  => 'kubernetes_pod_name',
                    },
                ],
            },
            {
                'job_name'        => 'calico-felix',
                'file_sd_configs' =>  [
                    {
                      'files' =>  [ "${targets_path}/calico-felix_*.yaml",
                                    "${targets_path}/calico-felix-controller_*.yaml"]
                    },
                ],
            },
        ]

        $max_block_duration = ($enable_thanos_upload and $disable_compaction) ? {
            true    => '2h',
            default => '24h',
        }

        prometheus::server { $k8s_cluster:
            listen_address        => "127.0.0.1:${port}",
            storage_retention     => $storage_retention,
            max_chunks_to_persist => $max_chunks_to_persist,
            memory_chunks         => $memory_chunks,
            global_config_extra   => $config_extra,
            scrape_configs_extra  => $scrape_configs_extra,
            min_block_duration    => '2h',
            max_block_duration    => $max_block_duration,
            alertmanagers         => $alertmanagers.map |$a| { "${a}:9093" },
        }

        prometheus::web { $k8s_cluster:
            proxy_pass => "http://localhost:${port}/${k8s_cluster}",
        }

        profile::thanos::sidecar { $k8s_cluster:
            prometheus_port     => $port,
            prometheus_instance => $k8s_cluster,
            enable_upload       => $enable_thanos_upload,
            min_time            => $thanos_min_time,
        }

        prometheus::rule { "rules_${k8s_cluster}.yml":
            instance => $k8s_cluster,
            source   => 'puppet:///modules/profile/prometheus/rules_k8s.yml',
        }

        prometheus::class_config { "calico-felix-${k8s_cluster}":
            dest           => "${targets_path}/calico-felix_${::site}.yaml",
            class_name     => $class_name,
            hostnames_only => false,
            port           => 9091,
        }

        if $controller_class_name {
            prometheus::class_config { "calico-felix-controller-${k8s_cluster}":
                dest           => "${targets_path}/calico-felix-controller_${::site}.yaml",
                class_name     => $controller_class_name,
                hostnames_only => false,
                port           => 9091,
            }
        }

        file { $bearer_token_file:
            ensure  => present,
            content => $client_token,
            mode    => '0400',
            owner   => 'prometheus',
            group   => 'prometheus',
        }

        prometheus::pint::source { $k8s_cluster:
            port => $port,
        }
    }
}
