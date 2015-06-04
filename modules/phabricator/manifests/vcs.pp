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

    sudo::user { 'www-data': privileges => [
        "ALL=(${settings['phd.user']}) SETENV: NOPASSWD: /usr/local/bin/git-http-backend",
    ] }
}
