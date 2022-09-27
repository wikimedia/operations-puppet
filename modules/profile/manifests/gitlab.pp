# TODO: add profile and parameter description.
class profile::gitlab(
    Stdlib::Fqdn $active_host = lookup('profile::gitlab::active_host'),
    Array[Stdlib::Fqdn] $passive_hosts = lookup('profile::gitlab::passive_hosts'),
    Boolean $enable_backup_sync = lookup('profile::gitlab::enable_backup_sync'),
    Stdlib::IP::Address::V4 $service_ip_v4 = lookup('profile::gitlab::service_ip_v4'),
    Stdlib::IP::Address::V6 $service_ip_v6 = lookup('profile::gitlab::service_ip_v6'),
    Stdlib::Host $service_name = lookup('profile::gitlab::service_name'),
    Stdlib::Unixpath $backup_dir_data = lookup('profile::gitlab::backup_dir_data'),
    Stdlib::Unixpath $backup_dir_config = lookup('profile::gitlab::backup_dir_config'),
    Array[Stdlib::IP::Address] $monitoring_whitelist  = lookup('profile::gitlab::monitoring_whitelist'),
    String $cas_label = lookup('profile::gitlab::cas_label'),
    Stdlib::Httpurl $cas_url = lookup('profile::gitlab::cas_url'),
    Boolean $cas_auto_create_users = lookup('profile::gitlab::cas_auto_create_users'),
    Boolean $csp_enabled = lookup('profile::gitlab::csp_enabled', {default_value => false}),
    Boolean $csp_report_only = lookup('profile::gitlab::csp_enabled', {default_value => false}),
    Integer[1] $backup_keep_time = lookup('profile::gitlab::backup_keep_time'),
    Boolean  $smtp_enabled = lookup('profile::gitlab::smtp_enabled'),
    Hash[Gitlab::Exporters,Gitlab::Exporter] $exporters = lookup('profile::gitlab::exporters', {default_value => {}}),
    Stdlib::Unixpath $cert_path = lookup('profile::gitlab::cert_path'),
    Stdlib::Unixpath $key_path = lookup('profile::gitlab::key_path'),
    Boolean $enable_restore = lookup('profile::gitlab::enable_restore', {default_value => false}),
    Boolean $use_acmechief = lookup('profile::gitlab::use_acmechief'),
    String $ferm_drange = lookup('profile::gitlab::ferm_drange'),
    Array[Stdlib::IP::Address] $ssh_listen_addresses = lookup('profile::gitlab::ssh_listen_addresses'),
    Array[Stdlib::IP::Address] $nginx_listen_addresses = lookup('profile::gitlab::nginx_listen_addresses'),
    Systemd::Timer::Schedule $full_backup_interval = lookup('profile::gitlab::full_backup_interval'),
    Systemd::Timer::Schedule $partial_backup_interval = lookup('profile::gitlab::partial_backup_interval'),
    Systemd::Timer::Schedule $config_backup_interval = lookup('profile::gitlab::config_backup_interval'),
    Systemd::Timer::Schedule $restore_interval = lookup('profile::gitlab::restore_interval:'),
    Systemd::Timer::Schedule $rsync_interval = lookup('profile::gitlab::rsync_interval:'),
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
        $facts['fqdn'] => 'critical',
        default        => 'warning'
    }

    if $active_host == $facts['fqdn'] {
        prometheus::blackbox::check::http { $service_name:
            team               => 'serviceops-collab',
            severity           => $severity,
            path               => '/explore',
            ip4                => $service_ip_v4,
            ip6                => $service_ip_v6,
            body_regex_matches => ['Discover projects, groups and snippets'],
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
        systemd::timer::job { 'certbot-renew':
            ensure      => present,
            user        => 'root',
            description => 'renew TLS certificate using certbot',
            command     => "/usr/bin/certbot -q renew --post-hook \"/usr/bin/gitlab-ctl hup nginx\"",
            interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* 05:05:00'},
        }
    }

    # add a service IP to the NIC - T276148
    interface::alias { 'gitlab service IP':
        ipv4 => $service_ip_v4,
        ipv6 => $service_ip_v6,
    }

    # open ports in firewall - T276144

    # world -> service IP, HTTP
    # http traffic is handled different on WMCS floating IPs
    ferm::service { 'gitlab-http-public':
        proto  => 'tcp',
        port   => 80,
        drange => $ferm_drange,
    }

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
        backup_dir_data         => $backup_dir_data,
        exporters               => $exporters,
        monitoring_whitelist    => $monitoring_whitelist,
        cas_label               => $cas_label,
        cas_url                 => $cas_url,
        cas_auto_create_users   => $cas_auto_create_users,
        csp_enabled             => $csp_enabled,
        csp_report_only         => $csp_report_only,
        backup_keep_time        => $backup_keep_time,
        smtp_enabled            => $smtp_enabled,
        enable_backup           => $active_host == $facts['fqdn'], # enable backups on active GitLab server
        ssh_listen_addresses    => $ssh_listen_addresses,
        nginx_listen_addresses  => $nginx_listen_addresses,
        install_restore_script  => $active_host != $facts['fqdn'], # install restore script on passive GitLab server
        enable_restore          => $enable_restore,
        cert_path               => $cert_path,
        key_path                => $key_path,
        gitlab_domain           => $service_name,
        full_backup_interval    => $full_backup_interval,
        partial_backup_interval => $partial_backup_interval,
        config_backup_interval  => $config_backup_interval,
        restore_interval        => $restore_interval,
        email_enable            => $active_host == $facts['fqdn'], # enable emails on active GitLab server
    }
}
