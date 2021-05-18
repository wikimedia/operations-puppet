# @summary configure and manage gitlab server
class gitlab (
    Wmflib::Ensure   $ensure                       = 'present',
    Stdlib::Host     $gitlab_domain                = $facts['networking']['fqdn'],
    Stdlib::Httpurl  $external_url                 = "https://${gitlab_domain}/",
    Stdlib::Unixpath $config_dir                   = '/etc/gitlab',
    Stdlib::Unixpath $data_dir                     = '/var/opt/gitlab/git-data',
    Stdlib::Unixpath $backup_dir                   = '/var/opt/gitlab/backups',
    Stdlib::Unixpath $cert_path                    = "${config_dir}/ssl/${gitlab_domain}.pem",
    Stdlib::Unixpath $key_path                     = "${config_dir}/ssl/${gitlab_domain}.key",
    Boolean          $enable_backup                = true,
    Integer[1]       $backup_keep_time             = 604800,
    Boolean          $email_enable                 = true,
    String           $email_from                   = "gitlab@${gitlab_domain}",
    String           $email_reply_to               = $email_from,
    String           $email_name                   = 'Gitlab',
    # TODO: should this be int?
    String           $default_theme                = '2',
    Boolean          $cas_auto_create_users        = true,
    Stdlib::Httpurl  $cas_url                      = 'https://cas.example.org',
    Stdlib::Unixpath $cas_login_uri                = '/login',
    Stdlib::Unixpath $cas_logout_uri               = '/logout',
    Stdlib::Unixpath $cas_validate_uri             = '/p3/serviceValidate',
    String           $cas_label                    = 'Cas Login',
    Boolean          $cas_sync_email               = true,
    Boolean          $cas_sync_profile             = true,
    Boolean          $cas_sync_attrs               = true,
    Hash             $extra_settings               = {},
    Boolean          $enable_node_exporter         = false,
    Boolean          $enable_prometheus            = false,
    Boolean          $enable_grafana               = false,
    Boolean          $enable_alertmanager          = false,
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

    if $enable_backup {
        include gitlab::backup
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
}
