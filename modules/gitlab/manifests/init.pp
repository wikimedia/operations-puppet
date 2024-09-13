# SPDX-License-Identifier: Apache-2.0
# @summary configure and manage gitlab server
# @param block_auto_created_users Blocks users that are automatically created
#   from signing in until they are approved by an administrator.
# @param sync_profile_attributes the attributes to sync
# @param omniauth_providers hash of provideres to configure.  the key is the label
# @param auto_sign_in_with automatically redirect to this provider
# @param omniauth_identifier name of the omniauth client identifier
# @omniauth_auto_link_saml_user automatically link SAML users with existing GitLab users if their email addresses match
# @max_storage_concurrency The maximum number of projects to back up at the same time on each storage
# @max_concurrency The maximum number of projects to back up at the same time. Should be to the number of logical CPUs.
# @logrotate_frequency frequency to rotate the logs (daily, weekly, monthly, or yearly)
# @logrotate_maxsize logs will be rotated when they grow bigger than size specified for `maxsize`, even before the specified time interval
# @logrotate_size enable or disable rotation by size
# @logrotate_rotate keep number of spcified logs
# @param enable_robots_txt serve a custom robots.txt
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
    Stdlib::Unixpath $rails_path                                = '/opt/gitlab/embedded/service/gitlab-rails',
    Stdlib::Unixpath $embedded_bin_path                         = '/opt/gitlab/embedded/bin',
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
    Boolean          $csp_enabled                               = false,
    Boolean          $csp_report_only                           = false,
    Hash             $extra_settings                            = {},
    Boolean          $enable_prometheus                         = false,
    Boolean          $enable_alertmanager                       = false,
    Array[Gitlab::Projects] $default_projects_features          = [],
    Boolean          $smtp_enabled                              = true,
    Integer          $smtp_port                                 = 25,
    Stdlib::IP::Address $exporter_default_listen                = '127.0.0.1',
    Array[Stdlib::IP::Address] $ssh_listen_addresses            = ['127.0.0.1', '::1'],
    Hash[Gitlab::Exporters,Gitlab::Exporter] $exporters         = {},
    Array[Stdlib::IP::Address] $monitoring_whitelist            = ['127.0.0.1/32'],
    Boolean          $enable_custom_exporter                    = false,
    Integer          $custom_exporter_port                      = 9169,
    Integer          $custom_exporter_interval                  = 60,
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
    Boolean           $omniauth_auto_link_saml_user             = true,
    String                   $gitlab_settings_user              = 'gitlab-settings',
    Boolean                  $enable_configure_projects         = false,
    String                   $configure_projects_bot            = 'configure-projects-bot',
    String                   $configure_projects_bot_token      = 'configure-projects-bot-token-not-supplied',
    Systemd::Timer::Schedule $configure_projects_interval       = {'start' => 'OnCalendar', 'interval' => '*-*-* 4:30:00'},
    Boolean                  $enable_ldap_group_sync            = false,
    Hash                     $ldap_config                       = {},
    String                   $ldap_group_sync_bot               = 'ldap-sync-bot',
    String                   $ldap_group_sync_bot_token         = 'ldap-sync-bot-token-not-supplied',
    Systemd::Timer::Schedule $ldap_group_sync_interval          = {'start' => 'OnCalendar', 'interval' => '*:0/15'},
    Boolean                  $thanos_storage_enabled            = false,
    String                   $thanos_storage_username           = '',
    String                   $thanos_storage_password           = '',
    Boolean                  $local_gems_enabled                = false,
    Hash[Stdlib::Unixpath, Array[String]] $local_gems           = {},
    Integer                  $max_storage_concurrency           = 4,
    Integer                  $max_concurrency                   = 2,
    Array[String]            $custom_nginx_config               = [],
    String                   $logrotate_frequency               = 'daily',
    String                   $logrotate_maxsize                 = 'nil',
    String                   $logrotate_size                    = 'nil',
    Integer                  $logrotate_rotate                  = 10,
    Boolean                  $enable_robots_txt                 = false,

) {
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

    $gemfile_local_ensure = $local_gems_enabled ? {
        true    => $ensure,
        default => 'absent',
    }

    file { "${rails_path}/Gemfile.local":
        ensure  => stdlib::ensure($gemfile_local_ensure),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('gitlab/Gemfile.local.erb'),
        require => Package['gitlab-ce'],
        notify  => Exec['Recreate GitLab Gemfile.local.lock'],
    }

    # Generate a Gemfile.local.lock, starting with Gemfile.lock as a base to
    # avoid attempts to resolve/update newer versions of upstream gem dependencies
    exec { 'Recreate GitLab Gemfile.local.lock':
        command     => "/bin/sh -c \"/usr/bin/cp Gemfile.lock Gemfile.local.lock && ${embedded_bin_path}/bundle lock --local\"",
        cwd         => $rails_path,
        environment => [
            'BUNDLE_GEMFILE=Gemfile.local',
            'BUNDLE_IGNORE_CONFIG=1',
        ],
        refreshonly => true,
        onlyif      => '/usr/bin/test -e Gemfile.local',
        require     => Package['gitlab-ce'],
        notify      => Service['gitlab-ce'],
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

    $ensure_robots_txt = $enable_robots_txt ? {
        true    => 'present',
        default => 'absent',
    }

    file { '/srv/robots.txt':
        ensure  => stdlib::ensure($ensure_robots_txt),
        owner   => 'gitlab-www',
        group   => 'gitlab-www',
        mode    => '0644',
        source  => 'puppet:///modules/gitlab/robots.txt',
        require => Package['gitlab-ce'],
        notify  => Exec['Reconfigure GitLab'],
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
        max_concurrency         => $max_concurrency,
        max_storage_concurrency => $max_storage_concurrency,
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

    ### gitlab-settings dependencies, including group management and configure-projects
    ensure_packages('python3-ldap')

    $ensure_gitlab_settings_user = ($enable_ldap_group_sync or $enable_configure_projects).bool2str('present','absent')
    systemd::sysuser { $gitlab_settings_user:
        ensure      => $ensure_gitlab_settings_user,
        description => 'user for scripts under gitlab-settings',
    }

    # Clone gitlab-settings repo for use by the LDAP sync and project
    # configuration bots.  Both will run as $gitlab_settings_user.
    $ensure_gitlab_settings = ($enable_ldap_group_sync or $enable_configure_projects).bool2str('latest','absent')
    # NOTE: Gitlab needs to be operational for this to work:
    git::clone { 'repos/releng/gitlab-settings':
        ensure        => $ensure_gitlab_settings,
        update_method => 'checkout',
        git_tag       => 'v1.7.0',
        directory     => '/srv/gitlab-settings',
        source        => 'gitlab',
        owner         => $gitlab_settings_user,
        group         => $gitlab_settings_user,
        require       => Systemd::Sysuser[$gitlab_settings_user],
    }

    # LDAP sync config file:
    $ensure_ldap_group_sync = $enable_ldap_group_sync.bool2str('present','absent')
    $ldap_url = "ldaps://${ldap_config[ro-server]}:636"
    file { "${config_dir}/group-management-config.yaml":
        ensure  => $ensure_ldap_group_sync,
        owner   => $gitlab_settings_user,
        group   => $gitlab_settings_user,
        mode    => '0400',
        content => template('gitlab/group-management-config.yaml.erb'),
        require => Systemd::Sysuser[$gitlab_settings_user],
    }

    # LDAP sync timer:
    $sync_cmd = "/srv/gitlab-settings/group-management/sync-gitlab-group-with-ldap -c ${config_dir}/group-management-config.yaml --yes"
    systemd::timer::job { 'sync-gitlab-group-with-ldap':
        ensure      => $ensure_ldap_group_sync,
        user        => $gitlab_settings_user,
        description => 'Sync various GitLab groups with their LDAP groups',
        command     => "${sync_cmd} repos/mediawiki wmf ops ; ${sync_cmd} --access-level Owner repos/sre ops",
        interval    => $ldap_group_sync_interval,
        require     => Systemd::Sysuser[$gitlab_settings_user],
    }

    # configure-projects config file (T355097)
    $ensure_configure_projects = $enable_configure_projects.bool2str('present', 'absent')
    file { "${config_dir}/configure-projects.yaml":
        ensure  => $ensure_configure_projects,
        owner   => $gitlab_settings_user,
        group   => $gitlab_settings_user,
        mode    => '0400',
        content => template('gitlab/configure-projects.yaml.erb'),
        require => Systemd::Sysuser[$gitlab_settings_user],
    }

    # configure-projects timer (T355097)
    $configure_projects_cmd = "/srv/gitlab-settings/configure-projects/configure-projects -c ${config_dir}/configure-projects.yaml"
    systemd::timer::job { 'gitlab-settings-configure-projects':
        ensure      => $ensure_configure_projects,
        user        => $gitlab_settings_user,
        description => 'Configure all projects on instance',
        command     => $configure_projects_cmd,
        interval    => $configure_projects_interval,
        require     => Systemd::Sysuser[$gitlab_settings_user],
    }

    $ensure_custom_exporter = $enable_custom_exporter.bool2str('latest','absent')
    git::clone { 'repos/sre/gitlab-exporter':
        ensure        => $ensure_custom_exporter,
        update_method => 'checkout',
        git_tag       => 'v1.0.11',
        directory     => '/srv/gitlab-exporter',
        source        => 'gitlab',
        owner         => 'prometheus',
        group         => 'prometheus',
    }

    $ensure_custom_exporter_service = $enable_custom_exporter.bool2str('present','absent')
    systemd::service { 'gitlab-exporter':
        ensure  => $ensure_custom_exporter_service,
        content => template('gitlab/gitlab-exporter.service.erb'),
        restart => true,
    }

    $ensure_custom_exporter_secret = $enable_custom_exporter.bool2str('file','absent')
    file { '/etc/gitlab-exporter-auth':
        ensure  => $ensure_custom_exporter_secret,
        owner   => 'prometheus',
        group   => 'prometheus',
        mode    => '0400',
        content => secret('gitlab/gitlab-exporter-auth'),
    }

    ensure_packages(['python3-gitlab'])
}
