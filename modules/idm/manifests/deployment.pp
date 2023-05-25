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
    Integer             $redis_port,
    Integer             $redis_maxmem,
){
    # We need django from backports to get latest LTS.
    if debian::codename::eq('bullseye') {
        apt::pin { 'python3-django':
            pin      => 'release a=bullseye-backports',
            package  => 'python3-django',
            priority => 1001,
        }
    }

    # Django configuration
    file { "${etc_dir}/settings.py":
        ensure  => present,
        content => template('idm/idm-django-settings.erb'),
        owner   => $deploy_user,
        group   => $deploy_user,

    }

    # We need the base configuration from the Bitu
    # project. This contain non-secret settings that
    # are generic for all Bitu projects.
    file { "${etc_dir}/base_settings.py":
        ensure => link,
        target => "${base_dir}/${project}/bitu/base_settings.py"
    }

    # During development we want to install Bitu and packages
    # in a virtual environment.
    if $install_via_git {
        ensure_packages(['python3-venv'])
        $venv = "${base_dir}/venv"

        file { $base_dir :
            ensure => directory,
            owner  => $deploy_user,
            group  => $deploy_user,
        }

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
    } else {
        # For future use.
        ensure_packages('python3-bitu-idm')
    }

    ferm::service { 'redis_replication':
        proto  => 'tcp',
        port   => $redis_port,
        srange => "@resolve((${redis_master} ${redis_replicas.join(' ')}))",
    }

    $base_redis_settings =  {
        bind        => $facts['networking']['ip'],
        maxmemory   => $redis_maxmem,
        port        => $redis_port,
        requirepass => $redis_password,
    }

    $replica_redis_settings = {
        replicaof  => "${$redis_master} ${redis_port}",
        masterauth => $redis_password,
    }

    unless $facts['networking']['hostname'] in $redis_master {
        $redis_settings = $base_redis_settings + $replica_redis_settings
    } else {
        $redis_settings =  $base_redis_settings
    }

    redis::instance { String($redis_port):
        settings => $redis_settings,
    }

    $logs = ['idm', 'django']
    $logs.each |$log| {
        logrotate::rule { "bitu-${log}":
        ensure        => present,
        file_glob     => "${log_dir}/${log}.log",
        frequency     => 'daily',
        not_if_empty  => true,
        copy_truncate => true,
        max_age       => 30,
        rotate        => 30,
        date_ext      => true,
        compress      => true,
        missing_ok    => true,
        no_create     => true,
        }
    }
}
