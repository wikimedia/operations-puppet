# == Class: phabricator::vcs
#
# Setup Phabricator to properly act as a version control system host.
#
# Much of this logic is based on the Diffusion setup guide
# https://secure.phabricator.com/book/phabricator/article/diffusion_hosting/
#
# [listen_addresses]
#  Array of IP's to listen for SSH
#
# [ssh_port]
#  Port SSH should listen on
#
class phabricator::vcs (
    Stdlib::Unixpath $basedir               = '/srv/phab',
    Stdlib::Unixpath $phd_log_dir           = '/var/log/phd',
    String $phd_user                        = 'phd',
    String $vcs_user                        = 'vcs',
    Array $listen_addresses                 = [],
    Integer $ssh_port                       = 22,
    String $proxy                           = "http://url-downloader.${::site}.wikimedia.org:8080",
    Wmflib::Ensure $ssh_phab_service_ensure = absent,
) {

    $ssh_hook_path = '/usr/libexec/phabricator-ssh-hook.sh'
    $sshd_config = '/etc/ssh/sshd_config.phabricator'

    systemd::sysuser { $vcs_user:
        ensure            => present,
        id                => '497:497',
        shell             => '/bin/sh',
        allow_login       => true,
        description       => 'Phabricator vcs user',
        home_dir          => "/var/lib/${vcs_user}",
        additional_groups => ['vcs','phd'],
    }

    file { "${basedir}/phabricator/scripts/ssh/":
        owner   => $vcs_user,
        recurse => true,
    }

    # git-http-backend needs to be in $PATH
    file { '/usr/local/bin/git-http-backend':
        ensure  => link,
        target  => '/usr/lib/git-core/git-http-backend',
        require => Package['git'],
    }

    file { "${phd_log_dir}/ssh.log":
        ensure  => present,
        owner   => $vcs_user,
        group   => 'root',
        mode    => '0640',
        require => File[$phd_log_dir],
    }

    # Configure all git repositories we host
    git::systemconfig { 'setup proxy':
        settings => {
            'http "https://gerrit.googlesource.com"'   => {
                'proxy' => $proxy,
            },
            'http "https://github.com"'                => {
                'proxy' => $proxy,
            },
            'http "https://gitlab.com"'                => {
                'proxy' => $proxy,
            },
            'http "https://gerrit.wikimedia.org"'      => {
                'proxy' => '',
            },
            'http "https://phabricator.wikimedia.org"' => {
                'proxy' => '',
            },
        }
    }

    file { '/usr/libexec':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { $ssh_hook_path:
        content => template('phabricator/vcs/phabricator-ssh-hook.sh.erb'),
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        require => File['/usr/libexec'],
    }

    # phd.user owns repo resources and both vcs and web user
    # must sudo to phd to for repo work.
    sudo::user { $vcs_user:
        privileges => [
            "ALL=(${phd_user}) SETENV: NOPASSWD: /usr/bin/git-upload-pack, /usr/bin/git-receive-pack, /usr/bin/svnserve",
        ],
        require    => User[$vcs_user],
    }

    sudo::user { 'www-data':
        privileges => [
            "ALL=(${phd_user}) SETENV: NOPASSWD: /usr/local/bin/git-http-backend, /usr/bin/git",
        ],
        require    => File['/usr/local/bin/git-http-backend'],
    }


}
