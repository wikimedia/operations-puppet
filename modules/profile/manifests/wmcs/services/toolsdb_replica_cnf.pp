# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::services::toolsdb_replica_cnf(
    String $tool_replica_cnf_path    = lookup('profile::wmcs::services::toolsdb_replica_cnf::tool_replica_cnf_path'),
    String $paws_replica_cnf_path    = lookup('profile::wmcs::services::toolsdb_replica_cnf::paws_replica_cnf_path'),
    String $user_replica_cnf_path    = lookup('profile::wmcs::services::toolsdb_replica_cnf::user_replica_cnf_path'),
    String $htuser                   = lookup('profile::wmcs::services::toolsdb_replica_cnf::htuser'),
    String $htpassword               = lookup('profile::wmcs::services::toolsdb_replica_cnf::htpassword'),
    String $htpassword_salt          = lookup('profile::wmcs::services::toolsdb_replica_cnf::htpassword_salt'),
    String $tools_project_prefix     = lookup('profile::wmcs::services::toolsdb_replica_cnf::tools_project_prefix'),
    String $kubeconfig_path_template = lookup('profile::wmcs::services::toolsdb_replica_cnf::kubeconfig_path_template'),
) {
    $user                           = 'www-data'
    $group                          = 'www-data'
    $replica_cnf_config_file_path   = '/etc/replica_cnf_config.yaml'
    $metrics_dir                    = '/run/toolsdb-replica-cnf-metrics'
    $htpassword_file                = '/etc/nginx/toolsdb-replica-cnf.htpasswd';
    $htpassword_hash                = htpasswd($htpassword, $htpassword_salt);

    apt::repository { 'toolforge':
        uri        => 'https://deb.svc.toolforge.org/repo',
        dist       => "${debian::codename()}-tools",
        components => 'main',
        trust_repo => true,
        source     => false,
    }

    stdlib::ensure_packages([
        'python3-flask',
        'python3-toolforge-weld',
        'python3-venv',
        'toolforge-replica-cnf',
        'bats',
    ])

    file { $replica_cnf_config_file_path:
        ensure  => 'file',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => {
            'TOOL_REPLICA_CNF_PATH' => $tool_replica_cnf_path,
            'PAWS_REPLICA_CNF_PATH' => $paws_replica_cnf_path,
            'USER_REPLICA_CNF_PATH' => $user_replica_cnf_path,
            'BACKENDS'              => {
                'ToolforgeToolFileBackend'    => {
                    'ToolforgeToolBackendConfig' => {
                        'replica_cnf_path'     => $tool_replica_cnf_path,
                        'tools_project_prefix' => $tools_project_prefix,
                        'use_sudo'             => true,
                    },
                },
                'ToolforgeUserFileBackend'    => {
                    'FileConfig' => {
                        'replica_cnf_path' => $user_replica_cnf_path,
                        'use_sudo'         => true,
                    },
                },
                'PawsUserFileBackend'         => {
                    'FileConfig' => {
                        'replica_cnf_path' => $paws_replica_cnf_path,
                        'use_sudo'         => true,
                    },
                },
                'ToolforgeToolEnvvarsBackend' => {
                    'EnvvarsConfig' => {
                        'kubeconfig_path_template' => $kubeconfig_path_template,
                        'toolforge_api_endpoint'   => "https://api.svc.${::wmcs_project}.${::wmcs_deployment}.wikimedia.cloud:30003",
                        'use_sudo'                 => true,
                    },
                },
            },
        }.stdlib::to_yaml(),
    }


    # Needed for prometheus exporter to share metrics between uwsgi processes
    file { $metrics_dir:
        ensure => 'directory',
        owner  => $user,
        group  => $group,
    }

    systemd::tmpfile { 'toolsdb-replica-cnf-shared-metrics':
        content => "d ${metrics_dir} 0755 ${user} ${group}",
    }

    uwsgi::app { 'toolsdb-replica-cnf-web':
        ensure             => 'present',
        subscribe          => [
            Package['toolforge-replica-cnf'],
            File[ $replica_cnf_config_file_path ],
        ],
        settings           => {
            uwsgi              => {
                'plugins'      => 'python3',
                'socket'       => '/run/uwsgi/toolsdb-replica-cnf-web.sock',
                'module'       => 'replica_cnf.views:create_app()',
                'chmod-socket' => 664,
                'die-on-term'  => true,
                'vacuum'       => true,
                'master'       => true,
                'processes'    => 8,
                'env'          => [
                    # fix prometheus exporter for multiple uwsgi processes/workers
                    "PROMETHEUS_MULTIPROC_DIR=${metrics_dir}",
                ],
            },
        },
        extra_systemd_opts => {
            'ExecStartPre' => [
                # Clear out metrics caches for previous runs
                "/bin/bash -c \"rm -rf ${metrics_dir}/*\"",
            ],
        },
    }

    file { $htpassword_file:
        content => "${htuser}:${htpassword_hash}",
        owner   => $user,
        group   => $group,
        mode    => '0440',
        before  => Service['nginx'],
        require => Package['nginx-common'],
    }

    nginx::site { 'toolsdb-replica-cnf-web-nginx':
        require => Uwsgi::App['toolsdb-replica-cnf-web'],
        content => epp('profile/wmcs/nfs/toolsdb-replica-cnf-web.nginx.epp'),
    }

}
