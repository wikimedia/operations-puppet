# Uses the prometheus module and generates the specific configuration
# needed for WMF production
#
class profile::prometheus::k8s (
    $users = hiera('k8s_infrastructure_users'), # lint:ignore:wmf_styleguide
){
    $targets_path = '/srv/prometheus/k8s/targets'
    $storage_retention = hiera('prometheus::server::storage_retention', '4032h')
    $max_chunks_to_persist = hiera('prometheus::server::max_chunks_to_persist', '524288')
    $memory_chunks = hiera('prometheus::server::memory_chunks', '1048576')
    $bearer_token_file = '/srv/prometheus/k8s/k8s.token'
    $master_host = "kubemaster.svc.${::site}.wmnet"
    $client_token = $users['prometheus']['token']

    $config_extra = {
        # All metrics will get an additional 'site' label when queried by
        # external systems (e.g. via federation)
        'external_labels' => {
            'site' => $::site,
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
            'job_name'              => 'k8s-pods',
            'bearer_token_file'     => $bearer_token_file,
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
    ]

    prometheus::server { 'k8s':
        listen_address        => '127.0.0.1:9906',
        storage_retention     => $storage_retention,
        max_chunks_to_persist => $max_chunks_to_persist,
        memory_chunks         => $memory_chunks,
        global_config_extra   => $config_extra,
        scrape_configs_extra  => $scrape_configs_extra,
    }

    prometheus::web { 'k8s':
        proxy_pass => 'http://localhost:9906/k8s',
    }

    prometheus::rule { 'rules_k8s.yml':
        instance => 'k8s',
        source   => 'puppet:///modules/profile/prometheus/rules_k8s.yml',
    }

    file { $bearer_token_file:
        ensure  => present,
        content => $client_token,
        mode    => '0400',
        owner   => 'prometheus',
        group   => 'prometheus',
    }
}
