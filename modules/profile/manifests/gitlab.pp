# SPDX-License-Identifier: Apache-2.0
# @summary Configure and manage GitLab server
# @param active_host The fully qualified domain name (FQDN) of the active GitLab host.
# @param auto_sign_in_with The provider to automatically sign in users with.
# @param backup_dir_config The directory path where configuration backups are stored.
# @param backup_dir_data The directory path where data backups are stored.
# @param backup_keep_time The duration (in seconds) to keep backups before deletion.
# @param block_auto_created_users Blocks users automatically created from signing in until approved by an administrator.
# @param configure_projects_bot_token The token for the bot user that configures project default settings.
# @param csp_enabled Enables Content Security Policy (CSP) for GitLab.
# @param csp_report_only Enables CSP in report-only mode, logging violations without enforcing the policy.
# @param custom_exporter_interval The interval (in seconds) at which the custom exporter collects data.
# @param custom_exporter_port The port on which the custom exporter listens.
# @param custom_nginx_config A list of custom NGINX configuration directives. Will be injected into the NGINX config.
# @param default_projects_features Default features to be enabled for new projects created in GitLab.
# @param enable_backup_sync Whether to enable synchronization of backups between active and passive hosts.
# @param enable_custom_exporter Whether to enable a custom exporter for metrics.
# @param external_url The external URL through which the GitLab instance is accessible.
# @param exporters A hash of exporter configurations for monitoring purposes.
# @param full_backup_interval The interval at which full backups should be taken (systemd timer notation).
# @param key_path The path to the SSL certificate key file.
# @param ldap_config The configuration hash for LDAP integration.
# @param ldap_group_sync_bot The username of the bot user for syncing LDAP groups.
# @param ldap_group_sync_bot_token The token for authenticating the LDAP group sync bot.
# @param ldap_group_sync_interval The interval at which LDAP group synchronization should occur.
# @param local_gems A hash mapping Unix paths to arrays of local gems to be installed. For extending GitLab with custom code/features)
# @param local_gems_enabled Whether to enable the use of local gems.
# @param logrotate_frequency The frequency at which log files should be rotated (daily, weekly, monthly, or yearly).
# @param logrotate_maxsize The maximum size a log file can reach before being rotated.
# @param logrotate_rotate The number of rotated log files to keep.
# @param logrotate_size Whether to enable log rotation based on file size.
# @param manage_host_keys Whether to manage git-ssh host keys through Puppet.
# @param max_concurrency The maximum number of concurrent operations during a backup.
# @param max_storage_concurrency The maximum number of concurrent storage operations during a backup.
# @param monitoring_whitelist A list of IP addresses allowed to access monitoring endpoints.
# @param nginx_listen_addresses An array of IP addresses on which NGINX should listen.
# @param omniauth_providers A hash of providers for configuring OmniAuth authentication.
# @param passive_hosts An array of FQDNs for passive GitLab hosts, used for failover.
# @param partial_backup_interval The interval at which partial backups should be taken (systemd timer notation).
# @param restore_interval The interval at which restores should be done (systemd timer notation).
# @param rsync_interval The interval for synchronizing data between active and passive hosts using rsync (systemd timer notation).
# @param service_ip_v4 The IPv4 address for the GitLab service.
# @param service_ip_v6 The IPv6 address for the GitLab service.
# @param service_name The name of the GitLab service, used for identification in various configurations.
# @param smtp_enabled Whether to enable SMTP for sending emails from GitLab.
# @param ssh_listen_addresses An array of IP addresses on which ssh-git daemon should listen.
# @param thanos_storage_enabled Whether to enable Thanos storage for GitLab.
# @param thanos_storage_password A hash containing the passwords for Thanos storage accounts.
# @param thanos_storage_username The username for accessing Thanos storage.
# @param use_acmechief Whether to use AcmeChief for certificate management.
# @param enable_robots_txt serve a custom robots.txt
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
    Array[String] $custom_nginx_config = lookup('profile::gitlab::custom_nginx_config'),
    String $logrotate_frequency = lookup('profile::gitlab::logrotate_frequency'),
    String $logrotate_maxsize = lookup('profile::gitlab::logrotate_maxsize'),
    String $logrotate_size = lookup('profile::gitlab::logrotate_size'),
    Integer $logrotate_rotate = lookup('profile::gitlab::logrotate_rotate'),
    Boolean $enable_robots_txt = lookup('profile::gitlab::enable_robots_txt'),
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
        firewall::service { 'gitlab-http-certbot':
          proto  => 'tcp',
          port   => [80],
          drange => [$service_ip_v4, $service_ip_v6]
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
    firewall::service { 'gitlab-https-public':
        proto  => 'tcp',
        port   => 443,
        drange => [$service_ip_v4, $service_ip_v6],
    }

    # world -> service IP, SSH
    firewall::service { 'gitlab-ssh-public':
        proto  => 'tcp',
        port   => 22,
        drange => [$service_ip_v4, $service_ip_v6],
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
        custom_nginx_config          => $custom_nginx_config,
        logrotate_frequency          => $logrotate_frequency,
        logrotate_maxsize            => $logrotate_maxsize,
        logrotate_size               => $logrotate_size,
        logrotate_rotate             => $logrotate_rotate,
        enable_robots_txt            => $enable_robots_txt,
    }
}
