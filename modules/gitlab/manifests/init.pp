# @summary configure and manage gitlab server
class gitlab (
    Wmflib::Ensure   $ensure                            = 'present',
    Stdlib::Host     $gitlab_domain                     = $facts['networking']['fqdn'],
    Stdlib::Port     $nginx_listen_port                 = 443,
    Array[Stdlib::IP::Address] $nginx_listen_addresses  = ['0.0.0.0'],
    Stdlib::Httpurl  $external_url                      = "https://${gitlab_domain}/",
    Stdlib::Unixpath $config_dir                        = '/etc/gitlab',
    Stdlib::Unixpath $data_dir                          = '/var/opt/gitlab/git-data',
    Stdlib::Unixpath $cert_path                         = "${config_dir}/ssl/${gitlab_domain}.pem",
    Stdlib::Unixpath $key_path                          = "${config_dir}/ssl/${gitlab_domain}.key",
    Boolean          $listent_https                     = true,
    Boolean          $enable_backup                     = true,
    Integer[1]       $backup_keep_time                  = 604800,
    Boolean          $gitlab_can_create_group           = false,
    Boolean          $gitlab_username_changing          = false,
    Boolean          $email_enable                      = true,
    String           $email_from                        = "gitlab@${gitlab_domain}",
    String           $email_reply_to                    = $email_from,
    String           $email_name                        = 'Gitlab',
    # TODO: should this be int?
    String           $default_theme                     = '2',
    Boolean          $cas_auto_create_users             = true,
    Stdlib::Httpurl  $cas_url                           = 'https://cas.example.org',
    Stdlib::Unixpath $cas_login_uri                     = '/login',
    Stdlib::Unixpath $cas_logout_uri                    = '/logout',
    Stdlib::Unixpath $cas_validate_uri                  = '/p3/serviceValidate',
    String           $cas_label                         = 'Cas Login',
    String           $cas_uid_field                     = 'uid',
    String           $cas_uid_key                       = 'uid',
    String           $cas_email_key                     = 'mail',
    String           $cas_name_key                      = 'cn',
    String           $cas_nickname_key                  = 'uid',
    Boolean          $cas_sync_email                    = true,
    Boolean          $cas_sync_profile                  = true,
    Boolean          $cas_sync_attrs                    = true,
    Integer          $cas_session_duration              = 604800,
    Boolean          $csp_enabled                       = false,
    Boolean          $csp_report_only                   = false,
    Hash             $extra_settings                    = {},
    Boolean          $enable_prometheus                 = false,
    Boolean          $enable_grafana                    = false,
    Boolean          $enable_alertmanager               = false,
    Array[Gitlab::Projects] $project_features           = [],
    Boolean          $smtp_enabled                      = true,
    Integer          $smtp_port                         = 25,
    Stdlib::IP::Address $exporter_default_listen        = '127.0.0.1',
    Array[Stdlib::IP::Address] $ssh_listen_addresses    = ['127.0.0.1', '::1'],
    Hash[Gitlab::Exporters,Gitlab::Exporter] $exporters = {},
    Array[Stdlib::IP::Address] $monitoring_whitelist    = ['127.0.0.1/32'],
    Boolean          $enable_secondary_sshd             = true,
    Boolean          $install_restore_script            = false,
    Boolean          $enable_restore                    = false,
    Stdlib::Unixpath $backup_dir_data                   = '/srv/gitlab-backup',
    Stdlib::Unixpath $backup_dir_config                 = '/etc/gitlab/config_backup',
    Systemd::Timer::Schedule $full_backup_interval      = {'start' => 'OnCalendar', 'interval' => '*-*-* 00:00:00'},
    Systemd::Timer::Schedule $config_backup_interval    = {'start' => 'OnCalendar', 'interval' => '*-*-* 00:00:00'},
    Systemd::Timer::Schedule $partial_backup_interval   = {'start' => 'OnCalendar', 'interval' => '*-*-* 00:00:00'},
    Systemd::Timer::Schedule $restore_interval          = {'start' => 'OnCalendar', 'interval' => '*-*-* 01:30:00'},
) {

    systemd::sysuser { 'git':
      id          => '915:915',
      description => 'git used by GitLab',
      home_dir    => '/var/opt/gitlab',
      allow_login => true,
    }

    if debian::codename::eq('bullseye') {
        apt::package_from_component{'gitlab-ce':
            component => 'thirdparty/gitlab-bullseye',
        }
    }
    else {
        apt::package_from_component{'gitlab-ce':
            component => 'thirdparty/gitlab',
        }
    }

    wmflib::dir::mkdir_p("${config_dir}/ssl", {
        owner => 'root',
        group => 'root',
        mode  => '0500',
    })
    file {'/etc/gitlab/gitlab.rb':
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('gitlab/gitlab.rb.erb'),
        notify  => Exec['Reconfigure GitLab'],
    }

    # From: https://github.com/voxpupuli/puppet-gitlab/blob/master/manifests/service.pp
    exec { 'Reconfigure GitLab':
        command     => '/bin/sh -c "unset LD_LIBRARY_PATH; /usr/bin/gitlab-ctl reconfigure"',
        refreshonly => true,
        timeout     => 1800,
        logoutput   => true,
        tries       => 5,
        require     => Package['gitlab-ce'],
        notify      => Service['gitlab-ce'],
    }

    service{ 'gitlab-ce':
        ensure  => stdlib::ensure($ensure, 'service'),
        start   => '/usr/bin/gitlab-ctl start',
        restart => '/usr/bin/gitlab-ctl restart',
        stop    => '/usr/bin/gitlab-ctl stop',
        status  => '/usr/bin/gitlab-ctl status',
        require => Package['gitlab-ce'],
    }

    # enable backups on active GitLab server
    $ensure_backup = $enable_backup.bool2str('present','absent')
    class { 'gitlab::backup':
        full_ensure             => $ensure_backup,
        partial_ensure          => 'absent',
        config_ensure           => $ensure_backup,
        backup_dir_data         => $backup_dir_data,
        backup_dir_config       => $backup_dir_config,
        backup_keep_time        => $backup_keep_time,
        full_backup_interval    => $full_backup_interval,
        partial_backup_interval => $partial_backup_interval,
        config_backup_interval  => $config_backup_interval,

    }

    # Theses parameters are installed by gitlab when the package is updated
    # However we purge this directory in puppet as such we need to add them here
    # TODO: Ensure theses values actually make sense
    sysctl::parameters {'omnibus-gitlab':
        priority => 90,
        values   => {
            'kernel.sem'         => '250 32000 32 262',
            'kernel.shmall'      => 4194304,
            'kernel.shmmax'      => 17179869184,
            'net.core.somaxconn' => 1024,
        },
    }

    # enable dedicated sshd for GitLab
    $ensure_sshd = $enable_secondary_sshd.bool2str('present','absent')
    class { 'gitlab::ssh' :
        ensure               => $ensure_sshd,
        ssh_listen_addresses => $ssh_listen_addresses,
    }

    # enable automated restore from backup (for replica)
    $ensure_restore_script = $install_restore_script.bool2str('present','absent')
    $ensure_restore = $enable_restore.bool2str('present','absent')
    class { 'gitlab::restore' :
        ensure_restore_script => $ensure_restore_script,
        ensure_restore        => $ensure_restore,
        restore_dir_data      => $backup_dir_data,
        restore_interval      => $restore_interval,
    }
}
