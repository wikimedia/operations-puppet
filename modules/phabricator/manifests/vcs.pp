# == Class: phabricator::vcs
#
# Setup Phabricator to properly act as a VCS host
#

class phabricator::vcs (
    $settings = {},
    $ssh_pid = '/var/run/sshd/phab.pid',
    $ssh_port = '22'
) {

    $ssh_user = $settings['diffusion.ssh-user']
    $phd_user = $settings['phd.user']
    $ssh_hook_path = '/usr/libexec/phabricator-ssh-hook.sh'

    # git-http-backend needs to be in $PATH
    file { '/usr/local/bin/git-http-backend':
        ensure  => 'link',
        target  => '/usr/lib/git-core/git-http-backend',
        require => Package['git'],
    }

    user { $ssh_user:
        home   => "/var/lib/${ssh_user}",
        shell  => '/bin/sh',
        system => true,
    }

    file { $ssh_hook_path:
        content => template('/phabricator/phabricator-ssh-hook.sh.erb'),
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
    }

    file { '/etc/ssh/sshd_config.phabricator':
        content => template('/phabricator/sshd_config.phabricator.erb'),
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
    }

    # phd.user owns repo resources and both vcs and web user
    # must sudo to phd to for repo work.

    sudo::user { $ssh_user:
        privileges => [
            "ALL=(${phd_user}) SETENV: NOPASSWD: /usr/bin/git-upload-pack, /usr/bin/git-receive-pack, /usr/bin/svnserve",
        ],
        require => User[$ssh_user],
    }

    sudo::user { 'www-data':
        privileges => [
            "ALL=(${phd_user}) SETENV: NOPASSWD: /usr/local/bin/git-http-backend",
        ],
        require    => File['/usr/local/bin/git-http-backend'],
    }
}
