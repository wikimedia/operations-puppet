# == Class: role::prometheus::tools
#
# This role provides both project-wide host discovery/monitoring (via cron
# prometheus-labs-targets) and kubernetes discovery/monitoring via Prometheus'
# native k8s support.

class role::prometheus::tools {
    $bearer_token_file = '/srv/prometheus/tools/k8s.token'
    $master_host = hiera('k8s::master_host')

    prometheus::server { 'tools':
        listen_address       => '127.0.0.1:9902',
        scrape_configs_extra => [
          {
            'job_name'              => 'k8s',
            'bearer_token_file'     => $bearer_token_file,
            'kubernetes_sd_configs' => [
              {
                'api_servers'       => [ "https://${master_host}:6443" ],
                'bearer_token_file' => $bearer_token_file,
              },
            ],
            # keep metrics coming from apiserver or node kubernetes roles
            # and map kubernetes node labels to prometheus metric labels
            'relabel_configs'       => [
              {
                'source_labels' => ['__meta_kubernetes_role'],
                'action'        => 'keep',
                'regex'         => '(?:apiserver|node)',
              },
              {
                'action' => 'labelmap',
                'regex'  => '__meta_kubernetes_node_label_(.+)',
              },
              {
                'source_labels' => ['__meta_kubernetes_role'],
                'action'        => 'replace',
                'target_label'  => 'kubernetes_role',
              },
            ]
          }
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

    include ::prometheus::scripts

    $targets_path = '/srv/prometheus/tools/targets/node_project.yml'
    cron { 'prometheus_tools_project_targets':
        ensure  => present,
        command => "/usr/local/bin/prometheus-labs-targets > ${targets_path}/node_project.$$ && mv ${targets_path}/node_project.$$ ${targets_path}/node_project.yml",
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
