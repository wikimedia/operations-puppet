# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::services::toolsdb_replica_cnf(
    String $user                    = lookup('profile::wmcs::services::toolsdb_replica_cnf::user'),
    String $secret_key              = lookup('profile::wmcs::services::toolsdb_replica_cnf::secret_key'),
    String $tools_replica_cnf_path  = lookup('profile::wmcs::services::toolsdb_replica_cnf::tools_replica_cnf_path'),
    String $paws_replica_cnf_path   = lookup('profile::wmcs::services::toolsdb_replica_cnf::paws_replica_cnf_path'),
    String $others_replica_cnf_path = lookup('profile::wmcs::services::toolsdb_replica_cnf::others_replica_cnf_path'),
    String $htpassword              = lookup('profile::wmcs::services::toolsdb_replica_cnf::htpassword'),
    String $htpassword_salt         = lookup('profile::wmcs::services::toolsdb_replica_cnf::htpassword_salt')
) {

    $www_data                      = 'www-data'
    $modules_uri                   = 'puppet:///modules/'
    $base_path                     = "/home/${user}"
    $api_service_base_path         = "${base_path}/replica_cnf_api_service"
    $api_service_app_path          = "${api_service_base_path}/replica_cnf_api_service"
    $api_service_app_path_in_repo  = "${modules_uri}profile/wmcs/nfs/replica_cnf_api_service/replica_cnf_api_service"
    $api_service_app_instance_path = "${api_service_app_path}/instance"
    $api_service_app_config_path   = "${api_service_app_instance_path}/config.py"
    $executables_paths             = '/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin'
    $metrics_dir                   = '/run/toolsdb-replica-cnf-metrics'
    $htpassword_file               = '/etc/nginx/toolsdb-replica-cnf.htpasswd';
    $htpassword_hash               = htpasswd($htpassword, $htpassword_salt);

    package { 'flask':
        ensure   => installed,
        name     => 'Flask>=2.0.0,<2.1.0',
        provider => 'pip3',
    }

    user { $user:
        ensure => present,
        system => true,
    }

    file { [$base_path, $api_service_base_path]:
        ensure  => 'directory',
        owner   => $user,
        group   => $www_data,
        require => User[ $user ],
    }

    file { $api_service_app_path:
        ensure  => 'directory',
        owner   => $user,
        group   => $www_data,
        require => File[ $base_path, $api_service_base_path ],
        recurse => true,
        source  => $api_service_app_path_in_repo,
        }

    file { $api_service_app_instance_path:
        ensure  => 'directory',
        owner   => $user,
        group   => $www_data,
        require => File[ $api_service_app_path ]
    }

    file { $api_service_app_config_path:
        ensure  => 'file',
        owner   => $user,
        group   => $www_data,
        require => File[ $api_service_app_path ],
        content => join([
                        "SECRET_KEY = '${secret_key}'",
                        "TOOLS_REPLICA_CNF_PATH = '${tools_replica_cnf_path}'",
                        "PAWS_REPLICA_CNF_PATH = '${paws_replica_cnf_path}'",
                        "OTHERS_REPLICA_CNF_PATH = '${others_replica_cnf_path}'"
                        ], "\n")
    }

    # ensure that auth files folders exist
    wmflib::dir::mkdir_p([
        $tools_replica_cnf_path,
        $paws_replica_cnf_path,
        $others_replica_cnf_path], {
        owner => $user,
        group => $www_data,
    })

    # Needed for prometheus exporter to share metrics between uwsgi processes
    file { $metrics_dir:
        ensure => 'directory',
        owner  => $www_data,
        group  => $www_data,
    }

    systemd::tmpfile { 'toolsdb-replica-cnf-shared-metrics':
        content => "d ${metrics_dir} 0755 ${www_data} ${www_data}",
    }

    uwsgi::app { 'toolsdb-replica-cnf-web':
        ensure             => 'present',
        subscribe          => [
            Package['flask'],
            File[ $api_service_base_path ],
            ],
        settings           => {
            uwsgi              => {
                'plugins'      => 'python3',
                'socket'       => '/run/uwsgi/toolsdb-replica-cnf-web.sock',
                'module'       => 'views:app',
                'chmod-socket' => 664,
                'die-on-term'  => true,
                'vacuum'       => true,
                'master'       => true,
                'processes'    => 8,
                'chdir'        => $api_service_app_path,
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
            content => "${user}:${htpassword_hash}",
            owner   => $www_data,
            group   => $www_data,
            mode    => '0440',
            before  => Service['nginx'],
            require => Package['nginx-common'],
    }

    nginx::site { 'toolsdb-replica-cnf-web-nginx':
        require => Uwsgi::App['toolsdb-replica-cnf-web'],
        content => template('profile/wmcs/nfs/toolsdb-replica-cnf-web.nginx.erb'),
    }

#    Install tmpreaper to clean up tempfiles leaked by xlsxwriter
#    T238375
#    package { 'tmpreaper':
#        ensure => 'installed',
#    }
#    file { '/etc/tmpreaper.conf':
#        owner   => 'root',
#        group   => 'root',
#        mode    => '0444',
#        source  => 'puppet:///modules/profile/toolsdb_replica_cnf/tmpreaper.conf',
#        require => Package['tmpreaper'],
#    }
}
