# @summary configure and manage gitlab server
class gitlab (
    Wmflib::Ensure   $ensure                            = 'present',
    Stdlib::Host     $gitlab_domain                     = $facts['networking']['fqdn'],
    Stdlib::Port     $listen_port                       = 443,
    Stdlib::Httpurl  $external_url                      = "https://${gitlab_domain}/",
    Stdlib::Unixpath $config_dir                        = '/etc/gitlab',
    Stdlib::Unixpath $data_dir                          = '/var/opt/gitlab/git-data',
    Stdlib::Unixpath $backup_dir                        = '/var/opt/gitlab/backups',
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
    Integer          $cas_session_duration              = 1,
    Hash             $extra_settings                    = {},
    Boolean          $enable_prometheus                 = false,
    Boolean          $enable_grafana                    = false,
    Boolean          $enable_alertmanager               = false,
    Array[Gitlab::Projects] $project_features           = [],
    Boolean          $smtp_enabled                      = true,
    Integer          $smtp_port                         = 25,
    Stdlib::IP::Address $exporter_default_listen        = '127.0.0.1',
    Array[Stdlib::IP::Address] $listen_addresses        = ['127.0.0.1', '::1'],
    Hash[Gitlab::Exporters,Gitlab::Exporter] $exporters = {},
    Array[Stdlib::IP::Address] $monitoring_whitelist    = ['127.0.0.1/32'],
    Boolean          $enable_secondary_sshd             = true,
    Boolean          $enable_restore_replica            = false,
) {

    apt::package_from_component{'gitlab-ce':
        component => 'thirdparty/gitlab',
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
        full_ensure       => $ensure_backup,
        partial_ensure    => 'absent',
        config_ensure     => $ensure_backup,
        backup_dir_data   => $gitlab::backup_dir_data,
        backup_dir_config => $gitlab::backup_dir_config,
        backup_keep_time  => $gitlab::backup_keep_time,
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
        ensure           => $ensure_sshd,
        listen_addresses => $listen_addresses,
    }

    # enable automated restore from backup (for replica)
    $ensure_restore_replica = $enable_restore_replica.bool2str('present','absent')
    class { 'gitlab::restore' :
        restore_ensure   => $ensure_restore_replica,
        restore_dir_data => $gitlab::backup_dir_data,
    }
}
