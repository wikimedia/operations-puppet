# == Class: role::prometheus::tools
#
# This role provides both project-wide host discovery/monitoring (via cron
# prometheus-labs-targets) and kubernetes discovery/monitoring via Prometheus'
# native k8s support.

class role::prometheus::tools {
    $bearer_token_file = '/srv/prometheus/tools/k8s.token'
    $targets_file = '/srv/prometheus/tools/targets/node_project.yml'
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
    $users = hiera('k8s_users')
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

    cron { 'prometheus_tools_project_targets':
        ensure  => present,
        command => "/usr/local/bin/prometheus-labs-targets > ${targets_file}.$$ && mv ${targets_file}.$$ ${targets_file}",
        minute  => '*/10',
        hour    => '*',
        user    => 'prometheus',
    }
}
