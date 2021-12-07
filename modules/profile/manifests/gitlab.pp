class profile::gitlab(
    Stdlib::Fqdn $active_host = lookup('profile::gitlab::active_host'),
    Stdlib::Fqdn $passive_host = lookup('profile::gitlab::passive_host'),
    Wmflib::Ensure $backup_sync_ensure = lookup('profile::gitlab::backup_sync::ensure'),
    Stdlib::IP::Address::V4 $service_ip_v4 = lookup('profile::gitlab::service_ip_v4'),
    Stdlib::IP::Address::V6 $service_ip_v6 = lookup('profile::gitlab::service_ip_v6'),
    Stdlib::Host $service_name = lookup('profile::gitlab::service_name'),
    Stdlib::Unixpath $backup_dir_data = lookup('profile::gitlab::backup_dir_data'),
    Stdlib::Unixpath $backup_dir_config = lookup('profile::gitlab::backup_dir_config'),
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes', {default_value => []}),
    Array[Stdlib::IP::Address] $monitoring_whitelist  = lookup('profile::gitlab::monitoring_whitelist'),
    String $cas_label = lookup('profile::gitlab::cas_label'),
    Stdlib::Httpurl $cas_url = lookup('profile::gitlab::cas_url'),
    Boolean $cas_auto_create_users = lookup('profile::gitlab::cas_auto_create_users'),
    Boolean $csp_enabled = lookup('profile::gitlab::csp_enabled', {default_value => false}),
    Boolean $csp_report_only = lookup('profile::gitlab::csp_enabled', {default_value => false}),
    Integer[1] $backup_keep_time = lookup('profile::gitlab::backup_keep_time'),
    Boolean  $smtp_enabled = lookup('profile::gitlab::smtp_enabled'),
    Hash[Gitlab::Exporters,Gitlab::Exporter] $exporters = lookup('profile::gitlab::exporters', {default_value => []}),
    Stdlib::Unixpath $cert_path = lookup('profile::gitlab::cert_path'),
    Stdlib::Unixpath $key_path = lookup('profile::gitlab::key_path'),
    Boolean $enable_restore_timer = lookup('profile::gitlab::enable_restore_timer', {default_value => true}),
){

    $acme_chief_cert = 'gitlab'

    # TODO move backup logic from profile to module
    if $active_host == $facts['fqdn'] {
        # Bacula backups, also see profile::backup::filesets (T274463)
        backup::set { 'gitlab':
            jobdefaults => 'Daily-production',  # full backups every day
        }
    }

    exec {'Reload nginx':
      command     => '/usr/bin/gitlab-ctl hup nginx',
      refreshonly => true,
    }

    # Certificates will be available under:
    # /etc/acmecerts/<%= @acme_chief_cert %>/live/
    acme_chief::cert { $acme_chief_cert:
        puppet_rsc => Exec['Reload nginx'],
    }

    # add a service IP to the NIC - T276148
    interface::alias { 'gitlab service IP':
        ipv4 => $service_ip_v4,
        ipv6 => $service_ip_v6,
    }

    # open ports in firewall - T276144

    # world -> service IP, HTTP
    ferm::service { 'gitlab-http-public':
        proto  => 'tcp',
        port   => 80,
        drange => "(${service_ip_v4} ${service_ip_v6})",
    }

    # world -> service IP, HTTPS
    ferm::service { 'gitlab-https-public':
        proto  => 'tcp',
        port   => 443,
        drange => "(${service_ip_v4} ${service_ip_v6})",
    }

    # world -> service IP, SSH
    ferm::service { 'gitlab-ssh-public':
        proto  => 'tcp',
        port   => 22,
        drange => "(${service_ip_v4} ${service_ip_v6})",
    }

    # create firewall rules for exporters T275170
    if !empty($prometheus_nodes) {
        # gitlab exports metrics on multiple ports and prometheus nodes need access
        $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
        $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

        $exporters.each |$exporter, $config| {
            unless $config['listen_address'] == '127.0.0.1' {
                ferm::service { "${exporter}_exporter":
                    proto  => 'tcp',
                    port   => $config['port'],
                    srange => $ferm_srange,
                }
            }
        }
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
        active_host  => $active_host,
        passive_host => $passive_host,
        ensure       => $backup_sync_ensure
    }

    class { 'gitlab':
        backup_dir             => $backup_dir_data,
        exporters              => $exporters,
        monitoring_whitelist   => $monitoring_whitelist,
        cas_label              => $cas_label,
        cas_url                => $cas_url,
        cas_auto_create_users  => $cas_auto_create_users,
        csp_enabled            => $csp_enabled,
        csp_report_only        => $csp_report_only,
        backup_keep_time       => $backup_keep_time,
        smtp_enabled           => $smtp_enabled,
        enable_backup          => $active_host == $facts['fqdn'], # enable backups on active GitLab server
        listen_addresses       => [$service_ip_v4, $service_ip_v6],
        enable_restore_replica => $active_host != $facts['fqdn'], # install restore script on passive GitLab server
        enable_restore_timer   => $active_host != $facts['fqdn'], # enable automated restore timer on passive GitLab server
        cert_path              => $cert_path,
        key_path               => $key_path,
        gitlab_domain          => $service_name,
    }
}
