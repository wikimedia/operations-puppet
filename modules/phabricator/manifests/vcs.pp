# == Class: phabricator::vcs
#
# Setup Phabricator to properly act as a VCS host
#
# Much of this logic is based on the Diffusion setup guide
# https://secure.phabricator.com/book/phabricator/article/diffusion_hosting/
#
# [*settings*]
#  Phab settings hash
#
# [listen_addresses]
#  Array of IP's to listen for SSH
#
# [ssh_port]
#  Port SSH should listen on

class phabricator::vcs (
    Stdlib::Unixpath $basedir = '/srv/phab',
    Hash $settings            = {},
    Array $listen_addresses   = [],
    Integer $ssh_port         = 22,
    String $proxy             = "http://url-downloader.${::site}.wikimedia.org:8080",
) {

    $phd_user = $settings['phd.user']
    $vcs_user = $settings['diffusion.ssh-user']
    $ssh_hook_path = '/usr/libexec/phabricator-ssh-hook.sh'
    $sshd_config = '/etc/ssh/sshd_config.phabricator'
    $phd_log_dir = $settings['phd.log-directory'];

    user { $vcs_user:
        gid        => 'phd',
        shell      => '/bin/sh',
        managehome => true,
        home       => "/var/lib/${vcs_user}",
        system     => true,
    }

    file { "${basedir}/phabricator/scripts/ssh/":
        owner   => $vcs_user,
        recurse => true,
    }

    # git-http-backend needs to be in $PATH
    file { '/usr/local/bin/git-http-backend':
        ensure  => 'link',
        target  => '/usr/lib/git-core/git-http-backend',
        require => Package['git'],
    }

    file { "${phd_log_dir}/ssh.log":
        ensure  => 'present',
        owner   => $vcs_user,
        group   => 'root',
        mode    => '0640',
        require => File[$phd_log_dir],
    }

    # Configure all git repositories we host
    file { '/etc/gitconfig':
        content => template('phabricator/vcs/system.gitconfig.erb'),
        require => Package['git'],
        owner   => 'root',
        group   => 'root',
    }

    file { '/usr/libexec':
        ensure => 'directory',
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

    if empty($listen_addresses) {
        # Emit a warning but allow listen_address to be empty, this is needed
        # for easier migrations from one server to another
        notify { 'Warning: phabricator::vcs::listen_address is empty': }
    } else {
        # allow ssh connection to IPs in hiera phabricator::vcs::listen_addresses:
        ferm::rule { 'ssh_public':
            rule => template('phabricator/vcs/ferm_rule-ssh_public.erb'),
        }

        file { $sshd_config:
            content => template('phabricator/vcs/sshd_config.phabricator.erb'),
            mode    => '0644',
            owner   => 'root',
            group   => 'root',
            require => Package['openssh-server'],
            notify  => Service['ssh-phab'],
        }

        systemd::service { 'ssh-phab':
            ensure  => 'present',
            content => systemd_template('ssh-phab'),
            require => Package['openssh-server'],
        }
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
            "ALL=(${phd_user}) SETENV: NOPASSWD: /usr/local/bin/git-http-backend",
        ],
        require    => File['/usr/local/bin/git-http-backend'],
    }


}
