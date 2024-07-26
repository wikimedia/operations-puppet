# SPDX-License-Identifier: Apache-2.0
# Uses the prometheus module and generates the specific configuration
# needed for WMF production
#
class profile::prometheus::k8s (
    String                     $replica_label          = lookup('prometheus::replica_label'),
    Boolean                    $enable_thanos_upload   = lookup('profile::prometheus::enable_thanos_upload', { 'default_value' => false }),
    Optional[String]           $thanos_min_time        = lookup('profile::prometheus::thanos::min_time', { 'default_value' => undef }),
    Array[Stdlib::Host]        $alertmanagers          = lookup('alertmanagers', { 'default_value' => [] }),
) {
    # Get all prometheus enabled k8s clusters for this DC, excluding aliases
    $enabled_k8s_clusters = k8s::fetch_clusters(false).filter | String $_, K8s::ClusterConfig $config | {
        $config['dc'] == $::site and 'prometheus' in $config
    }

    # Let's detect port duplications (per DC) and fail early
    $l = length($enabled_k8s_clusters.keys())
    $p = length(unique($enabled_k8s_clusters.map |String $_, K8s::ClusterConfig $c| { $c['prometheus']['port'] }))
    if $l != $p {
        fail('Port duplication detected in k8s_clusters declaration')
    }

    $enabled_k8s_clusters.each |String $cluster_name, K8s::ClusterConfig $k8s_config| {
        # k8s_cluster is the prometheus specific name for this cluster.
        # Unfortunately those are completely different from the actual cluster names
        $k8s_cluster = pick($k8s_config['prometheus']['name'], "k8s-${cluster_name}")
        $targets_path = "/srv/prometheus/${k8s_cluster}/targets"
        $master_url = $k8s_config['master_url']
        $port = $k8s_config['prometheus']['port']
        $storage_retention = $k8s_config['prometheus']['retention']
        $storage_retention_size = $k8s_config['prometheus']['retention_size']

        $client_cert = profile::pki::get_cert($k8s_config['pki_intermediate_base'], 'prometheus', {
            # 8759h in seconds. Temporarily longer client certs - https://phabricator.wikimedia.org/T343529
            'renew_seconds' => 31532400,
            'profile'       => 'prometheus',
            'names'         => [{ 'organisation' => 'system:monitoring' }],
            'owner'         => 'prometheus',
            'outdir'        => "/srv/prometheus/${k8s_cluster}/pki",
            'notify'        => Exec["prometheus@${k8s_cluster}-reload"],
        })

        # Authenticate to k8a API (and metrics endpoints) using a client certificate
        $k8s_sd_tls_config = {
            'cert_file' => $client_cert['cert'],
            'key_file'  => $client_cert['key'],
        }

        $config_extra = {
            # All metrics will get an additional 'site' label when queried by
            # external systems (e.g. via federation)
            'external_labels' => {
                'site'       => $::site,
                'replica'    => $replica_label,
                'prometheus' => $k8s_cluster,
            },
        }
        # Configure scraping from k8s cluster with distinct jobs. See comments in code below.
        # See also:
        # * https://prometheus.io/docs/operating/configuration/#<kubernetes_sd_config>
        # * https://github.com/prometheus/prometheus/blob/master/documentation/examples/prometheus-kubernetes.yml
        $scrape_configs_extra = [
            {
                # api server metrics (each one, as returned by k8s)
                'job_name'              => 'k8s-api',
                'tls_config'            => $k8s_sd_tls_config,
                'scheme'                => 'https',
                'kubernetes_sd_configs' => [
                    {
                        'api_server'        => $master_url,
                        'tls_config'        => $k8s_sd_tls_config,
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
                # kube-controller-manager metrics (on each k8s control-plane)
                'job_name'              => 'k8s-controller-manager',
                'tls_config'            => $k8s_sd_tls_config,
                'scheme'                => 'https',
                'kubernetes_sd_configs' => [
                    {
                        'api_server'        => $master_url,
                        'tls_config'        => $k8s_sd_tls_config,
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
                    {
                        # Rewrite the address, replacing the apiserver port with the kube-controller-manager one
                        'action'        => 'replace',  # Redundant but clearer
                        'source_labels' => ['__address__'],
                        'target_label'  => '__address__',
                        'regex'         => '([\d\.]+):(\d+)',
                        'replacement'   => "\${1}:10257",
                    },
                ],
            },
            {
                # kube-scheduler metrics (on each k8s control-plane)
                'job_name'              => 'k8s-scheduler',
                'tls_config'            => $k8s_sd_tls_config,
                'scheme'                => 'https',
                'kubernetes_sd_configs' => [
                    {
                        'api_server'        => $master_url,
                        'tls_config'        => $k8s_sd_tls_config,
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
                    {
                        # Rewrite the address, replacing the apiserver port with the kube-scheduler one
                        'action'        => 'replace',  # Redundant but clearer
                        'source_labels' => ['__address__'],
                        'target_label'  => '__address__',
                        'regex'         => '([\d\.]+):(\d+)',
                        'replacement'   => "\${1}:10259",
                    },
                ],
            },
            {
                # metrics from the kubelet running on each k8s node
                'job_name'              => 'k8s-node',
                'kubernetes_sd_configs' => [
                    {
                        'api_server'        => $master_url,
                        'tls_config'        => $k8s_sd_tls_config,
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
                # cadvisor metrics from the kubelet running on each k8s node
                'job_name'              => 'k8s-node-cadvisor',
                'metrics_path'          => '/metrics/cadvisor',
                'kubernetes_sd_configs' => [
                    {
                        'api_server'        => $master_url,
                        'tls_config'        => $k8s_sd_tls_config,
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
                ],
                'metric_relabel_configs' => [
                    # Drop the id label containing the slice-id of the container; T354604
                    {
                        'action'        => 'labeldrop',
                        'regex'         => 'id',
                    },
                ],
            },
            {
                # metrics from the kube-proxy running on each k8s node
                'job_name'              => 'k8s-node-proxy',
                'kubernetes_sd_configs' => [
                    {
                        'api_server'        => $master_url,
                        'tls_config'        => $k8s_sd_tls_config,
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
                # metrics from calico-felix, running in the nodes network namespace
                'job_name'        => 'calico-felix',
                'kubernetes_sd_configs' => [
                    {
                        'api_server'        => $master_url,
                        'tls_config'        => $k8s_sd_tls_config,
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
                        # Replace the port in the nodes address with that of calico-felix (9091)
                        'action'        => 'replace',  # Redundant but clearer
                        'source_labels' => ['__address__'],
                        'target_label'  => '__address__',
                        'regex'         => '([\d\.]+):(\d+)',
                        'replacement'   => "\${1}:9091",
                    },
                ]
            },
            {
                'job_name'              => 'k8s-pods',
                # Note: We dont verify the cert on purpose. Issues IP SAN based
                # certs for all pods is impossible
                'tls_config'            => {
                    insecure_skip_verify => true,
                },
                'kubernetes_sd_configs' => [
                    {
                        'api_server'        => $master_url,
                        'tls_config'        => $k8s_sd_tls_config,
                        'role'              => 'pod',
                    },
                ],
                'relabel_configs' => [
                    {
                        'action'        => 'keep',
                        'source_labels' => ['__meta_kubernetes_pod_annotation_prometheus_io_scrape'],
                        'regex'         => true,
                    },
                    # Avoid the Istio metrics in this job, so we can collect them
                    # separately in another one. We rely on the Istio
                    # sidecar.istio.io/inject K8s annotation to be present in all
                    # Pods running Istio, either an Ingress Gateway or a sidecar.
                    {
                        'action'        => 'drop',
                        'source_labels' => ['__meta_kubernetes_pod_annotation_sidecar_istio_io_inject'],
                        'regex'         => '(true|false)',
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
                # Note: We dont verify the cert on purpose. Issues IP SAN based
                # certs for all pods is impossible
                'tls_config'            => {
                    insecure_skip_verify => true,
                },
                'kubernetes_sd_configs' => [
                    {
                        'api_server'        => $master_url,
                        'tls_config'        => $k8s_sd_tls_config,
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
                # envoy metrics from the servic-proxy sidecar
                'job_name'              => 'k8s-pods-tls',
                'metrics_path'          => '/stats/prometheus',
                'params'                => { 'usedonly' => [''] },
                'scheme'                => 'http',
                'kubernetes_sd_configs' => [
                    {
                        'api_server'        => $master_url,
                        'tls_config'        => $k8s_sd_tls_config,
                        'role'              => 'pod',
                    },
                ],
                'metric_relabel_configs' => [
                    {
                        'source_labels' => ['__name__'],
                        'regex'         => '^envoy_((http_down|cluster_up)stream_(rq|cx)|runtime_|cluster_ratelimit).*$',
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
                # KServe specific metrics to monitor isvcs latency and GC activity
                'job_name'              => 'k8s-pods-kserve',
                'metrics_path'          => '/metrics',
                'scheme'                => 'http',
                'kubernetes_sd_configs' => [
                    {
                        'api_server'        => $master_url,
                        'tls_config'        => $k8s_sd_tls_config,
                        'role'              => 'pod',
                    },
                ],
                'relabel_configs' => [
                    {
                        'action'        => 'keep',
                        'source_labels' => ['__meta_kubernetes_pod_annotation_prometheus_kserve_io_scrape'],
                        'regex'         => true,
                    },
                    {
                        'action'        => 'replace',
                        'source_labels' => ['__address__', '__meta_kubernetes_pod_annotation_prometheus_kserve_io_port'],
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
                'metric_relabel_configs' => [
                    {
                        'action'        => 'labeldrop',
                        'regex'         => "(${[
                          'security_istio_io_tlsMode',
                          'service_istio_io_canonical_name',
                          'service_istio_io_canonical_revision',
                          'serving_knative_dev_configurationUID',
                          'serving_knative_dev_revision',
                          'serving_knative_dev_revisionUID',
                          'serving_knative_dev_service',
                          'serving_knative_dev_serviceUID',
                        ].join('|')})",
                    },
                ],
            },
            {
                # Istio metrics (Ingress and sidecars)
                'job_name'              => 'k8s-pods-istio',
                'scheme'                => 'http',
                'kubernetes_sd_configs' => [
                    {
                        'api_server'        => $master_url,
                        'tls_config'        => $k8s_sd_tls_config,
                        'role'              => 'pod',
                    },
                ],
                'relabel_configs' => [
                    # We rely on the Istio sidecar.istio.io/inject K8s annotation
                    # to be present in all Pods running Istio,
                    # either an Ingress Gateway or a sidecar.
                    {
                        'action'        => 'keep',
                        'source_labels' => ['__meta_kubernetes_pod_annotation_sidecar_istio_io_inject'],
                        'regex'         => '(true|false)',
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
                ],
                'metric_relabel_configs' => [
                    {
                        'action'        => 'labeldrop',
                        'regex'         => "(${[
                          'connection_security_policy',
                          'controller_revision_hash',
                          'istio_io_rev',
                          'source_canonical_revision',
                          'source_principal',
                          'source_version',
                          'install_operator_istio_io_owning_resource',
                          'operator_istio_io_component',
                          'service_istio_io_canonical_revision',
                          'sidecar_istio_io_inject',
                          'source_cluster',
                          'destination_principal',
                          'destination_version',
                          'destination_cluster',
                        ].join('|')})",
                    },
                ],
            },
        ]

        prometheus::server { $k8s_cluster:
            listen_address         => "127.0.0.1:${port}",
            storage_retention      => $storage_retention,
            storage_retention_size => $storage_retention_size,
            global_config_extra    => $config_extra,
            scrape_configs_extra   => $scrape_configs_extra,
            alertmanagers          => $alertmanagers.map |$a| { "${a}:9093" },
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

        prometheus::pint::source { $k8s_cluster:
            port => $port,
        }
    }
}
