# SPDX-License-Identifier: Apache-2.0

class profile::idm(
    Stdlib::Fqdn        $service_fqdn              = lookup('profile::idm::service_fqdn'),
    String              $django_secret_key         = lookup('profile::idm::server::django_secret_key'),
    String              $django_mysql_db_host      = lookup('profile::idm::server::django_mysql_db_host'),
    String              $django_mysql_db_password  = lookup('profile::idm::server::django_mysql_db_password'),
    String              $django_mysql_db_user      = lookup('profile::idm::server::django_mysql_db_user', {'default_value' => 'idm'}),
    String              $django_mysql_db_name      = lookup('profile::idm::server::django_mysql_db_name', {'default_value' => 'idm'}),
    String              $deploy_user               = lookup('profile::idm::deploy_user', {'default_value'                  => 'www-data'}),
    Integer             $uwsgi_process_count       = lookup('profile::idm::uwsgi_process_count', {'default_value'          => 4}),
    Boolean             $install_via_git           = lookup('profile::idm::install_via_git', {'default_value'              => false}),
    Boolean             $production                = lookup('profile::idm::production', {'default_value'                   => false}),
    Boolean             $envoy_termination         = lookup('profile::idm::envoy_termination', {'default_value'            => false}),
    Apereo_cas::Urls    $apereo_cas                = lookup('apereo_cas'),
    Hash                $ldap_config               = lookup('ldap'),
    String              $ldap_dn                   = lookup('profile::idm::ldap_dn'),
    String              $ldap_dn_password          = lookup('profile::idm::ldap_dn_password'),
    String              $oidc_key                  = lookup('profile::idm::oidc_service'),
    String              $oidc_secret               = lookup('profile::idm::oidc_secret'),
    String              $mediawiki_key             = lookup('profile::idm::mediawiki_key'),
    String              $mediawiki_secret          = lookup('profile::idm::mediawiki_secret'),
    Stdlib::Fqdn        $redis_master              = lookup('profile::idm::redis_master'),
    Array[Stdlib::Fqdn] $redis_replicas            = lookup('profile::idm::redis_replicas', {'default_value'               => []}),
    String              $redis_password            = lookup('profile::idm::redis_password', {'default_value'               => 'secret'}),
    Stdlib::Port        $redis_port                = lookup('profile::idm::redis_port', {'default_value'                   => 6973}),
    Integer             $redis_maxmem              = lookup('profile::idm::redis_maxmem', {'default_value'                 => 1610612736 }),
    Boolean             $enable_monitoring         = lookup('profile::idm::enable_monitoring'),
) {

    ensure_packages(['python3-django-uwsgi'])

    $etc_dir = '/etc/bitu'
    $base_dir = '/srv/idm'
    $log_dir = '/var/log/idm'
    $media_dir = "${base_dir}/media"
    $static_dir = "${base_dir}/static"
    $project = 'bitu'
    $uwsgi_socket = "/run/uwsgi/${project}.sock"

    $production_str = $production.bool2str('production', 'staging')
    $oidc_endpoint = $apereo_cas[$production_str]['oidc_endpoint']
    $oidc = { key      => $oidc_key,
              secret   => $oidc_secret,
              endpoint => $oidc_endpoint }

    $mediawiki = { key => $mediawiki_key, secret => $mediawiki_secret }

    include passwords::ldap::production
    class{ 'sslcert::dhparam': }

    if $envoy_termination {
      include profile::tlsproxy::envoy
      $ferm_port = 443
      profile::auto_restarts::service { 'envoyproxy': }
    } else {
      # In cloud we use the shared wmfcloud proxy for tls termination
      $ferm_port = 80
    }

    ferm::service { 'idm_http':
        proto => 'tcp',
        port  => $ferm_port,
    }

    file { [$base_dir, $static_dir, $media_dir, $etc_dir, $log_dir] :
        ensure => directory,
        owner  => $deploy_user,
        group  => $deploy_user,
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


    # Django configuration
    file { "${etc_dir}/settings.py":
        ensure  => present,
        content => template('idm/idm-django-settings.erb'),
        owner   => $deploy_user,
        group   => $deploy_user,

    }

    class { 'idm::redis':
        redis_master   => $redis_master,
        redis_replicas => $redis_replicas,
        redis_password => $redis_password,
        redis_port     => $redis_port,
        redis_maxmem   => $redis_maxmem,
    }


    if $install_via_git {
        class { 'idm::deployment':
            project                  => $project,
            service_fqdn             => $service_fqdn,
            django_secret_key        => $django_secret_key,
            django_mysql_db_name     => $django_mysql_db_name,
            django_mysql_db_host     => $django_mysql_db_host,
            django_mysql_db_user     => $django_mysql_db_user,
            django_mysql_db_password => $django_mysql_db_password,
            base_dir                 => $base_dir,
            deploy_user              => $deploy_user,
            etc_dir                  => $etc_dir,
            log_dir                  => $log_dir,
            static_dir               => $static_dir,
            install_via_git          => $install_via_git,
            redis_master             => $redis_master,
            redis_replicas           => $redis_replicas,
            redis_password           => $redis_password,
            redis_port               => $redis_port,
            redis_maxmem             => $redis_maxmem,
            oidc                     => $oidc,
            mediawiki                => $mediawiki,
            ldap_dn                  => $ldap_dn,
            ldap_dn_password         => $ldap_dn_password,
            ldap_config              => $ldap_config,
            production               => $production,
            uwsgi_process_count      => $uwsgi_process_count,

        }
    } else {
        ensure_packages('python3-bitu')

        service { 'uwsgi-bitu':
            ensure => 'running',
            enable => true
        }

        service { 'rq-bitu':
            ensure => stdlib::ensure($facts['networking']['fqdn'] == $redis_master, 'service'),
            enable => ($facts['networking']['fqdn'] == $redis_master)
        }

    }

    # Bitu is managed via a dedicated systemd unit (uwsgi-bitu.service),
    # mask the generic uwsgi unit which gets auto-translated based on the init.d script
    # shipped in the uwsgi Debian package
    systemd::mask { 'mask_default_uwsgi_bitu':
        unit => 'uwsgi.service',
    }

    class {'httpd':
        modules => ['proxy_http', 'proxy', 'proxy_uwsgi']
    }

    httpd::site { 'idm':
        ensure  => present,
        content => template('idm/idm-apache-config.erb'),
    }

    $job_state = ($facts['networking']['fqdn'] == $redis_master).bool2str('present', 'absent')
    class { 'idm::jobs':
        base_dir => $base_dir,
        etc_dir  => $etc_dir,
        project  => $project,
        present  => $job_state,
        venv     => "${base_dir}/venv",
        user     => $deploy_user
    }

    profile::auto_restarts::service { 'apache2':}
    profile::auto_restarts::service { 'rq-bitu':
        ensure => $job_state,
    }

    if $enable_monitoring {
        prometheus::blackbox::check::http { 'idm.wikimedia.org':
            team               => 'infrastructure-foundations',
            severity           => 'critical',
            path               => '/signup/',
            force_tls          => true,
            status_matches     => [200],
            body_regex_matches => ['signup'],
            follow_redirects   => true,
            probe_runbook      => 'https://wikitech.wikimedia.org/wiki/IDM/Runbook'
        }
    }
}
