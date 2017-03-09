# == Class: role::prometheus::tools
#
# This role provides both project-wide host discovery/monitoring (via cron
# prometheus-labs-targets) and kubernetes discovery/monitoring via Prometheus'
# native k8s support.
#
# filtertags: labs-project-tools
class role::prometheus::tools {
    $bearer_token_file = '/srv/prometheus/tools/k8s.token'
    $master_host = hiera('k8s::master_host')
    $targets_path = '/srv/prometheus/tools/targets'

    require ::role::labs::lvm::srv

    prometheus::server { 'tools':
        listen_address       => '127.0.0.1:9902',
        scrape_configs_extra => [
            {
                'job_name'              => 'k8s-api',
                'bearer_token_file'     => $bearer_token_file,
                'kubernetes_sd_configs' => [
                    {
                        'api_servers'       => [ "https://${master_host}:6443" ],
                        'bearer_token_file' => $bearer_token_file,
                        'role'              => 'apiserver',
                    },
                ],
            },
            {
                'job_name'              => 'k8s-node',
                'bearer_token_file'     => $bearer_token_file,
                # Force (insecure) https only for node servers
                'scheme'                => 'https',
                'tls_config'            => {
                    'insecure_skip_verify' => true,
                },
                'kubernetes_sd_configs' => [
                    {
                        'api_servers'       => [ "https://${master_host}:6443" ],
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
                    # Drop spammy metrics (i.e. with high cardinality k/v pairs)
                    {
                        'action'        => 'drop',
                        'regex'         => 'rest_client_request.*',
                        'source_labels' => [ '__name__' ],
                    },
                ]
            },
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
            'job_name'            => 'etcd',
            'file_sd_configs'     => [
                {
                    'files' => [ "${targets_path}/etcd_*.yml" ]
                }
            ]
            },
        ]
    }

    prometheus::web { 'tools':
        proxy_pass => 'http://localhost:9902/tools',
    }

    # Ugly hack, ugh! (from modules/toollabs/manifests/kube2proxy.pp)
    $users = hiera('k8s_infrastructure_users')
    $client_token = inline_template("<%= @users.select { |u| u['name'] == 'prometheus' }[0]['token'] %>")

    file { $bearer_token_file:
        ensure  => present,
        content => $client_token,
        mode    => '0400',
        owner   => 'prometheus',
        group   => 'prometheus',
        require => Prometheus::Server['tools'],
    }

    include ::role::prometheus::blackbox_exporter
    include ::prometheus::scripts

    cron { 'prometheus_tools_project_targets':
        ensure  => present,
        command => "/usr/local/bin/prometheus-labs-targets > ${targets_path}/node_project.$$ && mv ${targets_path}/node_project.$$ ${targets_path}/node_project.yml",
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

    cron { 'prometheus_tools_flannel_etcd_targets':
        ensure  => present,
        command => "/usr/local/bin/prometheus-labs-targets --port 9051 --prefix tools-flannel-etcd- > ${targets_path}/etcd_flannel.$$ && mv ${targets_path}/etcd_flannel.$$ ${targets_path}/etcd_flannel.yml",
        minute  => '*/10',
        hour    => '*',
        user    => 'prometheus',
    }
}
