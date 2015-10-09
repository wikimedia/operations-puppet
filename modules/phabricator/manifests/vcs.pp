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
    $basedir               = '/',
    $settings              = {},
    $listen_addresses      = [],
    $ssh_port              = '22',
) {

    $phd_user = $settings['phd.user']
    $vcs_user = $settings['diffusion.ssh-user']
    $ssh_hook_path = '/usr/local/lib/phabricator-ssh-hook.sh'

    user { $vcs_user:
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

    file { $ssh_hook_path:
        content => template('phabricator/phabricator-ssh-hook.sh.erb'),
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
    }

    file { '/etc/ssh/sshd_config.phabricator':
        content => template('phabricator/sshd_config.phabricator.erb'),
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        require => Package['openssh-server'],
    }

    # phd.user owns repo resources and both vcs and web user
    # must sudo to phd to for repo work.
    sudo::user { $vcs_user:
        privileges => [
            "ALL=(${phd_user}) SETENV: NOPASSWD: /usr/bin/git-upload-pack, /usr/bin/git-receive-pack, /usr/bin/svnserve",
        ],
        require => User[$vcs_user],
    }

    sudo::user { 'www-data':
        privileges => [
            "ALL=(${phd_user}) SETENV: NOPASSWD: /usr/local/bin/git-http-backend",
        ],
        require    => File['/usr/local/bin/git-http-backend'],
    }
}
