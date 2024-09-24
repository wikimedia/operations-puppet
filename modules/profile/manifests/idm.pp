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
    Optional[String[1]] $oidc_key                  = lookup('profile::idm::oidc_service'),
    Optional[String[1]] $oidc_secret               = lookup('profile::idm::oidc_secret'),
    Optional[String[1]] $mediawiki_key             = lookup('profile::idm::mediawiki_key'),
    Optional[String[1]] $mediawiki_secret          = lookup('profile::idm::mediawiki_secret'),
    Optional[String[1]] $mediawiki_callback        = lookup('profile::idm::mediaback_callback'),
    Optional[Hash]      $mediawiki_oauth           = lookup('profile::idm::mediawiki_oauth', {'default_value'              => undef}),
    Stdlib::Fqdn        $redis_master              = lookup('profile::idm::redis_master'),
    Array[Stdlib::Fqdn] $redis_replicas            = lookup('profile::idm::redis_replicas', {'default_value'               => []}),
    String              $redis_password            = lookup('profile::idm::redis_password', {'default_value'               => 'secret'}),
    Stdlib::Port        $redis_port                = lookup('profile::idm::redis_port', {'default_value'                   => 6973}),
    Integer             $redis_maxmem              = lookup('profile::idm::redis_maxmem', {'default_value'                 => 1610612736 }),
    Boolean             $enable_monitoring         = lookup('profile::idm::enable_monitoring'),
    String              $config_template           = lookup('profile::idm::config_template', {'default_value'              => 'idm/idm-django-settings.erb'}),
    Boolean             $enable_api                = lookup('profile::idm::enable_api', {'default_value'                   => false}),
    Optional[String[1]] $gitlab_token              = lookup('profile::idm::gitlab_token'),
    Optional[String[1]] $phabricator_token         = lookup('profile::idm::phabricator_token'),
    Optional[String[1]] $gerrit_user               = lookup('profile::idm::gerrit_username'),
    Optional[String[1]] $gerrit_password           = lookup('profile::idm::gerrit_password')
) {

    ensure_packages(['python3-django-uwsgi', 'python3-django-auth-ldap'])

    $etc_dir = '/etc/bitu'
    $base_dir = '/srv/idm'
    $log_dir = '/var/log/idm'
    $media_dir = "${base_dir}/media"
    $static_dir = "${base_dir}/static"
    $project = 'bitu'
    $uwsgi_socket = "/run/uwsgi/${project}.sock"

    $production_str = $production.bool2str('production', 'staging')

    if $oidc_key {
    $oidc_endpoint = $apereo_cas[$production_str]['oidc_endpoint']
        $oidc = { key      => $oidc_key,
                  secret   => $oidc_secret,
                  endpoint => $oidc_endpoint }
    }

    if $mediawiki_callback {
        $mediawiki = { key => $mediawiki_key, secret => $mediawiki_secret, callback => $mediawiki_callback }
    }

    include passwords::ldap::production
    class{ 'sslcert::dhparam': }

    if $envoy_termination {
      include profile::tlsproxy::envoy
      $firewall_port = 443
      profile::auto_restarts::service { 'envoyproxy': }
    } else {
      # In Cloud VPS we use the shared web proxy for tls termination
      $firewall_port = 80
    }

    firewall::service { 'idm_http':
        proto => 'tcp',
        port  => $firewall_port,
    }

    file { [$base_dir, $static_dir, $media_dir, $etc_dir, $log_dir] :
        ensure => directory,
        owner  => $deploy_user,
        group  => $deploy_user,
    }

    $logs = ['idm', 'django']

    $logs.each |$log| {
        file { $log:
        ensure => file,
        path   => "${log_dir}/${log}.log",
        owner  => $deploy_user,
        group  => $deploy_user,
        }
    }


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
        content => template($config_template),
        owner   => $deploy_user,
        group   => $deploy_user,
        notify  => Service['uwsgi-bitu', 'rq-bitu'],
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
            project             => $project,
            base_dir            => $base_dir,
            deploy_user         => $deploy_user,
            redis_master        => $redis_master,
            uwsgi_process_count => $uwsgi_process_count,

        }
    } else {
        ensure_packages(['python3-bitu', 'python3-mysqldb', 'python3-bs4'])

        # Enable Bitu uwsgi app.
        file { '/etc/uwsgi/apps-enabled/bitu.ini':
            ensure => 'link',
            target => '/etc/uwsgi/apps-available/bitu.ini',
        }

        # The systemd services is shipped with the Debian package,
        # but we need the services to be available to Puppet to be
        # used with Notify on configuration changes.
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
        modules => ['proxy_http', 'proxy', 'proxy_uwsgi', 'remoteip']
    }

    httpd::site { 'idm':
        ensure  => present,
        content => template('idm/idm-apache-config.erb'),
    }

    $job_state = ($facts['networking']['fqdn'] == $redis_master).bool2str('present', 'absent')
    class { 'idm::jobs':
        present => $job_state,
        user    => $deploy_user
    }

    profile::auto_restarts::service { 'apache2':}
    profile::auto_restarts::service { 'rq-bitu':
        ensure => $job_state,
    }
    profile::auto_restarts::service { 'uwsgi-bitu':}


    if $enable_monitoring {
        prometheus::blackbox::check::http { $service_fqdn:
            team               => 'infrastructure-foundations',
            severity           => 'critical',
            path               => '/accounts/login/',
            force_tls          => true,
            status_matches     => [200],
            body_regex_matches => ['account'],
            follow_redirects   => true,
            probe_runbook      => 'https://wikitech.wikimedia.org/wiki/IDM/Runbook'
        }
    }
}
