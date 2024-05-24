# SPDX-License-Identifier: Apache-2.0
# TODO: add profile and parameter description.
# @summary configure and manage gitlab server
# @param block_auto_created_users Blocks users that are automatically created
#   from signing in until they are approved by an administrator.
# @param omniauth_providers hash of providers to configure.  the key is the label
# @param auto_sign_in_with automatically redirect to this provider
class profile::gitlab(
    Stdlib::Fqdn $active_host = lookup('profile::gitlab::active_host'),
    Array[Stdlib::Fqdn] $passive_hosts = lookup('profile::gitlab::passive_hosts'),
    Boolean $enable_backup_sync = lookup('profile::gitlab::enable_backup_sync'),
    Stdlib::IP::Address::V4 $service_ip_v4 = lookup('profile::gitlab::service_ip_v4'),
    Stdlib::IP::Address::V6 $service_ip_v6 = lookup('profile::gitlab::service_ip_v6'),
    Stdlib::Host $service_name = lookup('profile::gitlab::service_name'),
    Stdlib::Httpurl $external_url = lookup('profile::gitlab::external_url'),
    Stdlib::Unixpath $backup_dir_data = lookup('profile::gitlab::backup_dir_data'),
    Stdlib::Unixpath $backup_dir_config = lookup('profile::gitlab::backup_dir_config'),
    Array[Stdlib::IP::Address] $monitoring_whitelist  = lookup('profile::gitlab::monitoring_whitelist'),
    Boolean $block_auto_created_users = lookup('profile::gitlab::block_auto_created_users'),
    Boolean $csp_enabled = lookup('profile::gitlab::csp_enabled', {default_value => false}),
    Boolean $csp_report_only = lookup('profile::gitlab::csp_enabled', {default_value => false}),
    Integer[1] $backup_keep_time = lookup('profile::gitlab::backup_keep_time'),
    Boolean  $smtp_enabled = lookup('profile::gitlab::smtp_enabled'),
    Array[Gitlab::Projects] $default_projects_features = lookup('profile::gitlab::default_projects_features', {default_value => []}),
    Hash[Gitlab::Exporters,Gitlab::Exporter] $exporters = lookup('profile::gitlab::exporters', {default_value => {}}),
    Boolean $enable_custom_exporter = lookup('profile::gitlab::enable_custom_exporter', {default_value => true}),
    Integer $custom_exporter_port = lookup('profile::gitlab::custom_exporter_port', {default_value => 9169}),
    Integer $custom_exporter_interval = lookup('profile::gitlab::custom_exporter_interval', {default_value => 60}),
    Stdlib::Unixpath $cert_path = lookup('profile::gitlab::cert_path'),
    Stdlib::Unixpath $key_path = lookup('profile::gitlab::key_path'),
    Boolean $use_acmechief = lookup('profile::gitlab::use_acmechief'),
    String $ferm_drange = lookup('profile::gitlab::ferm_drange'),
    Array[Stdlib::IP::Address] $ssh_listen_addresses = lookup('profile::gitlab::ssh_listen_addresses'),
    Array[Stdlib::IP::Address] $nginx_listen_addresses = lookup('profile::gitlab::nginx_listen_addresses'),
    Systemd::Timer::Schedule $full_backup_interval = lookup('profile::gitlab::full_backup_interval'),
    Systemd::Timer::Schedule $partial_backup_interval = lookup('profile::gitlab::partial_backup_interval'),
    Systemd::Timer::Schedule $config_backup_interval = lookup('profile::gitlab::config_backup_interval'),
    Systemd::Timer::Schedule $restore_interval = lookup('profile::gitlab::restore_interval:'),
    Systemd::Timer::Schedule $rsync_interval = lookup('profile::gitlab::rsync_interval:'),
    Boolean $manage_host_keys = lookup('profile::ssh::server::manage_host_keys', {default_value => false}),
    Gitlab::Omniauth_providers $auto_sign_in_with = lookup('profile::gitlab::auto_sign_in_with'),
    Hash[String, Gitlab::Omniauth_provider] $omniauth_providers = lookup('profile::gitlab::omniauth_providers'),
    Hash $ldap_config = lookup('ldap'),
    String $ldap_group_sync_user = lookup('profile::gitlab::ldap_group_sync_user'),
    String $ldap_group_sync_bot = lookup('profile::gitlab::ldap_group_sync_bot_user'),
    String $ldap_group_sync_bot_token = lookup('profile::gitlab::ldap_group_sync_bot_token'),
    String $configure_projects_bot_token = lookup('profile::gitlab::configure_projects_bot_token'),
    Systemd::Timer::Schedule $ldap_group_sync_interval = lookup('profile::gitlab::ldap_group_sync_interval_interval'),
    Boolean $thanos_storage_enabled = lookup('profile::gitlab::thanos_storage_enabled', {default_value => false}),
    String $thanos_storage_username = lookup('profile::gitlab::thanos_storage_username', {default_value => ''}),
    Hash[String, String] $thanos_storage_password = lookup('profile::thanos::swift::accounts_keys', {default_value => {}}),
    Boolean $local_gems_enabled = lookup('profile::gitlab::local_gems_enabled', {default_value => false}),
    Hash[Stdlib::Unixpath, Array[String]] $local_gems = lookup('profile::gitlab::local_gems', {default_value => {}}),
    Integer $max_storage_concurrency = lookup('profile::gitlab::max_storage_concurrency'),
    Integer $max_concurrency = lookup('profile::gitlab::max_concurrency'),
){

    $acme_chief_cert = 'gitlab'

    # TODO move backup logic from profile to module
    if $active_host == $facts['fqdn'] {
        # Bacula backups, also see profile::backup::filesets (T274463)
        backup::set { 'gitlab':
            jobdefaults => 'Daily-productionEqiad',  # full backups every day
        }
    }

    $severity = $active_host ? {
        $facts['fqdn'] => 'task',
        default        => 'task'
    }

    # use gitlab_oidc client on active host and gitlab_replica_oidc on replicas
    $omniauth_identifier = $active_host ? {
        $facts['fqdn'] => 'gitlab_oidc',
        default        => 'gitlab_replica_oidc'
    }

    if $active_host == $facts['fqdn'] {
        prometheus::blackbox::check::http { $service_name:
            team               => 'collaboration-services',
            severity           => $severity,
            path               => '/explore',
            ip4                => $service_ip_v4,
            ip6                => $service_ip_v6,
            body_regex_matches => ['GitLab Community Edition'],
        }
        prometheus::blackbox::check::tcp { "${service_name}-ssh":
            team     => 'collaboration-services',
            severity => $severity,
            ip4      => $service_ip_v4,
            ip6      => $service_ip_v6,
            port     => 22,
        }
    }

    exec {'Reload nginx':
      command     => '/usr/bin/gitlab-ctl hup nginx',
      refreshonly => true,
    }

    if $use_acmechief {
        # Certificates will be available under:
        # /etc/acmecerts/<%= @acme_chief_cert %>/live/
        acme_chief::cert { $acme_chief_cert:
            puppet_rsc => Exec['Reload nginx'],
        }
    } else {
        ensure_packages('certbot')
        # Mask the default certbot timer
        systemd::mask { 'certbot.timer': }
        systemd::timer::job { 'certbot-renew':
            ensure      => present,
            user        => 'root',
            description => 'renew TLS certificate using certbot',
            command     => "/usr/bin/certbot -q renew --post-hook \"/usr/bin/gitlab-ctl hup nginx\"",
            interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* 05:05:00'},
        }
        # Certbot has to be reached over port 80
        ferm::service { 'gitlab-http-certbot':
          proto  => 'tcp',
          port   => 80,
          drange => $ferm_drange,
        }
    }

    # add a service IP to the NIC - T276148
    interface::alias { 'gitlab service IP':
        ipv4   => $service_ip_v4,
        ipv6   => $service_ip_v6,
        notify => Service['ssh-gitlab']
    }

    # open ports in firewall - T276144

    # world -> service IP, HTTPS
    ferm::service { 'gitlab-https-public':
        proto  => 'tcp',
        port   => 443,
        drange => $ferm_drange,
    }

    # world -> service IP, SSH
    ferm::service { 'gitlab-ssh-public':
        proto  => 'tcp',
        port   => 22,
        drange => $ferm_drange,
    }

    # JSON Logs
    rsyslog::input::file { 'gitlab-gitaly-json':
      path => '/var/log/gitlab/gitaly/current',
    }

    rsyslog::input::file { 'gitlab-rails-production-json':
      path => '/var/log/gitlab/gitlab-rails/production_json.log',
    }

    rsyslog::input::file { 'gitlab-rails-api-json':
      path => '/var/log/gitlab/gitlab-rails/api_json.log',
    }

    rsyslog::input::file { 'gitlab-rails-application-json':
      path => '/var/log/gitlab/gitlab-rails/application_json.log',
    }

    rsyslog::input::file { 'gitlab-rails-exceptions-json':
      path => '/var/log/gitlab/gitlab-rails/exceptions_json.log',
    }

    rsyslog::input::file { 'gitlab-workhorse-json':
      path => '/var/log/gitlab/gitlab-workhorse/current',
    }

    rsyslog::input::file { 'gitlab-sidekiq-json':
      path => '/var/log/gitlab/sidekiq/current',
    }

    # @cee Json Logs
    rsyslog::input::file { 'gitlab-nginx-access-cee':
      path => '/var/log/gitlab/nginx/gitlab_access.log',
    }

    # Plain logs
    rsyslog::input::file { 'gitlab-nginx-error-plain':
      path => '/var/log/gitlab/nginx/gitlab_error.log',
    }

    rsyslog::input::file { 'gitlab-redis-plain':
      path => '/var/log/gitlab/redis/current',
    }

    # TODO T274462
    # rsyslog::input::file { 'gitlab-postgres':
    #   path => '/var/log/gitlab/postgresql/current',
    # }

    # T285867 sync active and passive GitLab server backups

    # rsync server is needed on passive server only
    $ensure_rsyncd = $active_host ? {
        $facts['fqdn'] => 'stopped',
        default        => 'running'
    }

    class { 'rsync::server':
        ensure_service => $ensure_rsyncd
    }

    class { 'gitlab::rsync':
        active_host       => $active_host,
        passive_hosts     => $passive_hosts,
        ensure            => $enable_backup_sync.bool2str('present','absent'),
        rsync_interval    => $rsync_interval,
        backup_dir_data   => $backup_dir_data,
        backup_dir_config => $backup_dir_config,
    }

    class { 'gitlab':
        backup_dir_data              => $backup_dir_data,
        exporters                    => $exporters,
        enable_custom_exporter       => $enable_custom_exporter,
        custom_exporter_port         => $custom_exporter_port,
        custom_exporter_interval     => $custom_exporter_interval,
        monitoring_whitelist         => $monitoring_whitelist,
        block_auto_created_users     => $block_auto_created_users,
        csp_enabled                  => $csp_enabled,
        csp_report_only              => $csp_report_only,
        backup_keep_time             => $backup_keep_time,
        smtp_enabled                 => $smtp_enabled,
        default_projects_features    => $default_projects_features,
        enable_backup                => $active_host == $facts['fqdn'], # enable backups on active GitLab server
        ssh_listen_addresses         => $ssh_listen_addresses,
        nginx_listen_addresses       => $nginx_listen_addresses,
        enable_restore               => $active_host != $facts['fqdn'], # enable restore on replicas
        cert_path                    => $cert_path,
        key_path                     => $key_path,
        gitlab_domain                => $service_name,
        external_url                 => $external_url,
        full_backup_interval         => $full_backup_interval,
        partial_backup_interval      => $partial_backup_interval,
        config_backup_interval       => $config_backup_interval,
        restore_interval             => $restore_interval,
        email_enable                 => $active_host == $facts['fqdn'], # enable emails on active GitLab server
        manage_host_keys             => $manage_host_keys,
        omniauth_providers           => $omniauth_providers,
        auto_sign_in_with            => $auto_sign_in_with,
        omniauth_identifier          => $omniauth_identifier,
        enable_ldap_group_sync       => $active_host == $facts['fqdn'], # enable LDAP group sync on active Gitlab server
        ldap_config                  => $ldap_config,
        ldap_group_sync_user         => $ldap_group_sync_user,
        ldap_group_sync_bot          => $ldap_group_sync_bot,
        ldap_group_sync_bot_token    => $ldap_group_sync_bot_token,
        ldap_group_sync_interval     => $ldap_group_sync_interval,
        enable_configure_projects    => $active_host == $facts['fqdn'], # enable configure-projects on active Gitlab server
        configure_projects_bot_token => $configure_projects_bot_token,
        thanos_storage_enabled       => $thanos_storage_enabled,
        thanos_storage_username      => $thanos_storage_username,
        thanos_storage_password      => $thanos_storage_password['gitlab'],
        local_gems_enabled           => $local_gems_enabled,
        local_gems                   => $local_gems,
        max_storage_concurrency      => $max_storage_concurrency,
        max_concurrency              => $max_concurrency,
    }
}
