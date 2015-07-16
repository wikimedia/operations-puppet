# == Class: phabricator::vcs
#
# Setup Phabricator to properly act as a VCS host
#

class phabricator::vcs (
    $settings = {},
) {

    # git-http-backend needs to be in $PATH
    file { '/usr/local/bin/git-http-backend':
        ensure => 'link',
        target => '/usr/lib/git-core/git-http-backend',
    }

    user { $settings['diffusion.ssh-user']:
        home   => "/var/lib/${settings['diffusion.ssh-user']}",
        shell  => '/bin/sh',
        system => true,
    }

    sudo::user { $settings['diffusion.ssh-user']:
        privileges => [
            "ALL=(${settings['phd.user']}) SETENV: NOPASSWD: /usr/bin/git-upload-pack, /usr/bin/git-receive-pack, /usr/bin/svnserve",
        ]
    }

    sudo::user { 'www-data':
        privileges => [
            "ALL=(${settings['phd.user']}) SETENV: NOPASSWD: /usr/local/bin/git-http-backend",
        ]
    }
}
