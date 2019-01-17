# == Class: mediawiki::users
#
# Provisions system accounts for running, deploying and updating
# MediaWiki.
#
class mediawiki::users(
    String $web = 'www-data',
) {

    # The mwdeploy account is used by various scripts in the MediaWiki
    # deployment process to run rsync.

    group { 'mwdeploy':
        ensure => present,
        system => true,
    }

    user { 'mwdeploy':
        ensure     => present,
        shell      => '/bin/bash',
        home       => '/var/lib/mwdeploy',
        system     => true,
        managehome => true,
    }

    ssh::userkey { 'mwdeploy':
        content => secret('keyholder/mwdeploy.pub'),
    }

    # Grant mwdeploy sudo rights to run anything as itself, apache and the
    # l10nupdate user. This allows MediaWiki deployers to deploy as mwdeploy.
    sudo::user { 'mwdeploy':
        privileges => [
            "ALL = (${web},mwdeploy,l10nupdate) NOPASSWD: ALL",
            'ALL = (root) NOPASSWD: /usr/sbin/service hhvm restart',
            'ALL = (root) NOPASSWD: /usr/sbin/service apache2 start',
            'ALL = (root) NOPASSWD: /usr/sbin/service hhvm start',
            'ALL = (root) NOPASSWD: /usr/sbin/apache2ctl graceful-stop',
        ],
    }

    # The pybal-check account is used by PyBal to monitor server health
    # See <https://wikitech.wikimedia.org/wiki/LVS#SSH_checking>

    group { 'pybal-check':
        ensure => present,
    }

    user { 'pybal-check':
        ensure     => present,
        gid        => 'pybal-check',
        shell      => '/bin/sh',
        home       => '/var/lib/pybal-check',
        system     => true,
        managehome => true,
    }

    ssh::userkey { 'pybal-check':
        source  => 'puppet:///modules/mediawiki/pybal_key',
    }
}
