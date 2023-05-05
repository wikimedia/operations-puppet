# SPDX-License-Identifier: Apache-2.0
# @summary configure and manage gitlab server
# @param block_auto_created_users Blocks users that are automatically created
#   from signing in until they are approved by an administrator.
# @param sync_profile_attributes the attributes to sync
# @param omniauth_providers hash of provideres to configure.  the key is the label
# @param auto_sign_in_with automatically redirect to this provider
# @param omniauth_identifier name of the omniauth client identifier
class gitlab (
    Wmflib::Ensure   $ensure                                    = 'present',
    Stdlib::Host     $gitlab_domain                             = $facts['networking']['fqdn'],
    Stdlib::Port     $nginx_listen_port                         = 443,
    Array[Stdlib::IP::Address] $nginx_listen_addresses          = ['0.0.0.0'],
    Stdlib::Httpurl  $external_url                              = "https://${gitlab_domain}/",
    Stdlib::Unixpath $config_dir                                = '/etc/gitlab',
    Stdlib::Unixpath $data_dir                                  = '/var/opt/gitlab/git-data',
    Stdlib::Unixpath $cert_path                                 = "${config_dir}/ssl/${gitlab_domain}.pem",
    Stdlib::Unixpath $key_path                                  = "${config_dir}/ssl/${gitlab_domain}.key",
    Boolean          $listen_https                              = true,
    Boolean          $enable_backup                             = true,
    Integer[1]       $backup_keep_time                          = 604800,
    Boolean          $gitlab_username_changing                  = false,
    Boolean          $email_enable                              = true,
    String           $email_from                                = "gitlab@${gitlab_domain}",
    String           $email_reply_to                            = $email_from,
    String           $email_name                                = 'Gitlab',
    # TODO: should this be int?
    String           $default_theme                             = '2',
    Integer          $cas_session_duration                      = 604800,
    Boolean          $csp_enabled                               = false,
    Boolean          $csp_report_only                           = false,
    Hash             $extra_settings                            = {},
    Boolean          $enable_prometheus                         = false,
    Boolean          $enable_grafana                            = false,
    Boolean          $enable_alertmanager                       = false,
    Array[Gitlab::Projects] $project_features                   = [],
    Boolean          $smtp_enabled                              = true,
    Integer          $smtp_port                                 = 25,
    Stdlib::IP::Address $exporter_default_listen                = '127.0.0.1',
    Array[Stdlib::IP::Address] $ssh_listen_addresses            = ['127.0.0.1', '::1'],
    Hash[Gitlab::Exporters,Gitlab::Exporter] $exporters         = {},
    Array[Stdlib::IP::Address] $monitoring_whitelist            = ['127.0.0.1/32'],
    Boolean          $enable_secondary_sshd                     = true,
    Boolean          $install_restore_script                    = true,
    Boolean          $enable_restore                            = false,
    Stdlib::Unixpath $backup_dir_data                           = '/srv/gitlab-backup',
    Stdlib::Unixpath $backup_dir_config                         = '/etc/gitlab/config_backup',
    Systemd::Timer::Schedule $full_backup_interval              = {'start' => 'OnCalendar', 'interval' => '*-*-* 00:00:00'},
    Systemd::Timer::Schedule $config_backup_interval            = {'start' => 'OnCalendar', 'interval' => '*-*-* 00:00:00'},
    Systemd::Timer::Schedule $partial_backup_interval           = {'start' => 'OnCalendar', 'interval' => '*-*-* 00:00:00'},
    Systemd::Timer::Schedule $restore_interval                  = {'start' => 'OnCalendar', 'interval' => '*-*-* 01:30:00'},
    Boolean $manage_host_keys                                   = false,
    Boolean                           $block_auto_created_users = true,
    Array[Gitlab::Attributes]          $sync_profile_attributes = ['name', 'email', 'location'],
    Hash[String, Gitlab::Omniauth_provider] $omniauth_providers = {},
    Optional[Gitlab::Omniauth_providers]    $auto_sign_in_with  = undef,
    Boolean           $letsencrypt_enable                       = false,
    String            $omniauth_identifier                      = 'gitlab_oidc',
) {
    $cas_defaults = {
        'login_url'            => '/login',
        'logout_url'           => '/logout',
        'service_validate_url' => '/p3/serviceValidate',
        'label'                => 'Cas Login',
        'uid_field'            => 'uid',
        'uid_key'              => 'uid',
        'email_key'            => 'mail',
        'name_key'             => 'cn',
        'nickname_key'         => 'uid',
    }
    $oidc_defaults = {
        'scope'                        => ['openid','profile','email'],
        'response_type'                => 'code',
        'discovery'                    => true,
        'client_auth_method'           => 'query',
        'uid_field'                    => 'sub',
        'send_scope_to_token_endpoint' => 'false',
        'pkce'                         => 'true',
        # TODO: the documents add the name filed to the args but
        # i suspect its a big in the docs
        'name'                         => 'openid_connect',
        'client_options'               => {
            'identifier' => $omniauth_identifier,
        },
    }

    $_omniauth_providers = $omniauth_providers.map |$label, $args| {
        case $args {
            Gitlab::Omniauth_provider::Cas3: {
                {
                    'label' => $label,
                    'name'  => 'cas3',
                    'args'  => $args + $cas_defaults,
                }
            }
            Gitlab::Omniauth_provider::OIDC: {
                if $args['client_options'].has_key('secret') {
                    {
                        'label' => $label,
                        'name'  => 'openid_connect',
                        'args'  => deep_merge($args, $oidc_defaults),
                    }
                } else {
                    warning("provider ${label} has no secret will not configure")
                }
            }
            default: { fail("omniauth_provider (${label}) is unsupported") }
        }
    }.filter |$item| { !$item.empty }
    $configured_providers = $_omniauth_providers.map |$provider| { $provider['name'] }.sort.unique

    systemd::sysuser { 'git':
      id          => '915:915',
      description => 'git used by GitLab',
      home_dir    => '/var/opt/gitlab',
      allow_login => true,
    }

    apt::package_from_component{'gitlab-ce':
        component => 'thirdparty/gitlab-bullseye',
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
        partial_ensure          => $ensure_backup,
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
            'kernel.sem'    => '250 32000 32 262',
            'kernel.shmall' => 4194304,
            'kernel.shmmax' => 17179869184,
        },
    }

    # enable dedicated sshd for GitLab
    $ensure_sshd = $enable_secondary_sshd.bool2str('present','absent')
    class { 'gitlab::ssh' :
        ensure               => $ensure_sshd,
        ssh_listen_addresses => $ssh_listen_addresses,
        manage_host_keys     => $manage_host_keys,
        gitlab_domain        => $gitlab_domain,
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

    # Install configuration file for gitlab backup partition layout.
    file {'/opt/gitlab-backup-raid.cfg':
        mode   => '0744' ,
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/gitlab/gitlab-backup-raid.cfg';
    }

    # Install scipt to configure backup partition layout and raid.
    # This script is executed manually while provisioning a new GitLab instance.
    file {'/opt/provision-backup-fs.sh':
        mode   => '0744' ,
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/gitlab/provision-backup-fs.sh';
    }
}
