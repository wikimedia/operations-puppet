# == Class: phabricator::vcs
#
# Setup Phabricator to properly act as a VCS host
#

class phabricator::vcs (
    $settings = {},
) {

    # git-http-backend needs to be in $PATH
    file { '/usr/local/bin/git-http-backend':
        ensure  => 'link',
        target  => '/usr/lib/git-core/git-http-backend',
        require => Package['git-core'],
    }


    user { $settings['diffusion.ssh-user']:
        home     => "/var/lib/${settings['diffusion.ssh-user']}",
        comment  => 'Phabricator VCS user'
        password => 'NP',
        shell    => '/bin/sh',
        system   => true,
    }

    # phd.user owns repo resources and both vcs and web user
    # must sudo to phd to for repo work.

    sudo::user { $settings['diffusion.ssh-user']:
        privileges => [
            "ALL=(${settings['phd.user']}) SETENV: NOPASSWD: /usr/bin/git-upload-pack, /usr/bin/git-receive-pack, /usr/bin/svnserve",
        ],
        require => User[$settings['diffusion.ssh-user']],
    }

    sudo::user { 'www-data':
        privileges => [
            "ALL=(${settings['phd.user']}) SETENV: NOPASSWD: /usr/local/bin/git-http-backend",
        ],
        require    => File['/usr/local/bin/git-http-backend'],
    }
}
