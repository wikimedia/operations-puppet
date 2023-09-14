# SPDX-License-Identifier: Apache-2.0

class idm::deployment (
    String              $project,
    Stdlib::Fqdn        $service_fqdn,
    String              $django_secret_key,
    String              $django_mysql_db_host,
    String              $django_mysql_db_name,
    String              $django_mysql_db_user,
    String              $django_mysql_db_password,
    Stdlib::Unixpath    $base_dir,
    String              $deploy_user,
    Stdlib::Unixpath    $etc_dir,
    Stdlib::Unixpath    $static_dir,
    Stdlib::Unixpath    $log_dir,
    Boolean             $install_via_git,
    Hash                $oidc,
    Hash                $mediawiki,
    Hash                $ldap_config,
    Stdlib::Fqdn        $redis_master,
    Array[Stdlib::Fqdn] $redis_replicas,
    String              $redis_password,
    Stdlib::Port        $redis_port,
    Integer             $redis_maxmem,
    String              $ldap_dn,
    String              $ldap_dn_password,
    Boolean             $production,
    Integer             $uwsgi_process_count,
){
    # We need django from backports to get latest LTS.
    if debian::codename::eq('bullseye') {
        apt::pin { 'python3-django':
            pin      => 'release a=bullseye-backports',
            package  => 'python3-django',
            priority => 1001,
        }
    }

    # We need the base configuration from the Bitu
    # project. This contain non-secret settings that
    # are generic for all Bitu projects.
    file { "${etc_dir}/base_settings.py":
        ensure => link,
        target => "${base_dir}/${project}/bitu/base_settings.py",
        notify => Service['uwsgi-bitu', 'rq-bitu']
    }

    # During development we want to install Bitu and packages
    # in a virtual environment.
    ensure_packages(['python3-venv'])
    $venv = "${base_dir}/venv"
    $uwsgi_socket = "/run/uwsgi/${project}.sock"

    git::clone { 'operations/software/bitu':
        ensure    => 'latest',
        directory => "${base_dir}/${project}",
        branch    => 'master',
        owner     => $deploy_user,
        group     => $deploy_user,
        source    => 'gerrit',
        notify    => Exec["install requirements to ${venv}"],
    }

    exec { "create virtual environment ${venv}":
        command => "/usr/bin/python3 -m venv ${venv}",
        creates => "${venv}/bin/activate",
    }

    exec { "install requirements to ${venv}":
        command     => "${venv}/bin/pip3 install -r ${base_dir}/${project}/requirements.txt",
        require     => Exec["create virtual environment ${venv}"],
        notify      => Exec['collect static assets'],
        refreshonly => true,
    }

    exec { 'collect static assets':
        command     => "${base_dir}/venv/bin/python ${base_dir}/${project}/manage.py collectstatic  --no-input",
        environment => ["PYTHONPATH=${etc_dir}", 'DJANGO_SETTINGS_MODULE=settings'],
        notify      => Service['uwsgi-bitu', 'rq-bitu'],
        refreshonly => true,
    }

    uwsgi::app{ $project:
        settings => {
            uwsgi => {
                'plugins'      => 'python3',
                'project'      => $project,
                'uid'          => $deploy_user,
                'base'         => "${base_dir}/${project}",
                'env'          => [
                    "PYTHONPATH=/etc/${project}:\$PYTHONPATH",
                    'DJANGO_SETTINGS_MODULE=settings'
                ],
                'chdir'        => '%(base)/',
                'module'       => '%(project).wsgi:application',
                'master'       => true,
                'processes'    => $uwsgi_process_count,
                'socket'       => $uwsgi_socket,
                'chown-socket' => $deploy_user,
                'chmod-socket' => 660,
                'vacuum'       => true,
                'virtualenv'   => "${base_dir}/venv"
            }
        }
    }

    systemd::service { 'rq-bitu':
        ensure  => ($facts['networking']['fqdn'] == $redis_master).bool2str('present', 'absent'),
        content => file('idm/rq-bitu.service')
    }
}
