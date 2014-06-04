# == Class: mediawiki::users
#
# Provisions system accounts for running, deploying and updating
# MediaWiki.
#
class mediawiki::users {

    # For legacy reasons, we run Apache / MediaWiki using an 'apache' user
    # rather than use the Debian default 'www-data'. The name, gid, home,
    # and shell of the apache user are set to conform with the postinst
    # script of the wikimedia-task-appserver package, which provisioned it
    # historically. These values can and should be modernized.

    generic::systemuser { 'apache':
        name          => 'apache',
        home          => '/var/www',
        managehome    => false,
        shell         => '/sbin/nologin',
        default_group => 'apache',
        default_group_gid => 48,
    }

    # The mwdeploy account is used by various scripts in the MediaWiki
    # deployment process to run rsync.

    generic::systemuser { 'mwdeploy':
        name          => 'mwdeploy',
        home          => '/var/lib/mwdeploy',
        shell         => '/bin/false',
        default_group => 'mwdeploy',
    }

    # The l10nupdate account is used for updating the localisation files
    # with new interface message translations.

    generic::systemuser { 'l10nupdate':
        name              => 'l10nupdate',
        home              => '/home/l10nupdate',
        shell             => '/bin/bash',
        default_group     => 'l10nupdate',
        default_group_gid => 1002,
    }

    file { '/home/l10nupdate/.ssh':
        ensure => directory,
        owner  => 'l10nupdate',
        group  => 'l10nupdate',
        mode   => '0500',
    }

    file { '/home/l10nupdate/.ssh/authorized_keys':
        owner   => 'l10nupdate',
        group   => 'l10nupdate',
        mode    => '0400',
        source  => 'puppet:///modules/mediawiki/authorized_keys.l10nupdate',
    }

    sudo_group { 'wikidev':
        privileges => [
            'ALL = (apache,mwdeploy,l10nupdate) NOPASSWD: ALL',
            'ALL = (root) NOPASSWD: /sbin/restart twemproxy',
            'ALL = (root) NOPASSWD: /sbin/start twemproxy',
            'ALL = NOPASSWD: /usr/sbin/apache2ctl',
            'ALL = NOPASSWD: /etc/init.d/apache2',
            'ALL = NOPASSWD: /usr/bin/renice',
        ],
    }

    sudo_user { 'l10nupdate':
        require    => User['l10nupdate', 'mwdeploy'],
        privileges => ['ALL = (mwdeploy) NOPASSWD: ALL'],
    }


    # The pybal-check account is used by PyBal to monitor server health
    # See <https://wikitech.wikimedia.org/wiki/LVS#SSH_checking>

    generic::systemuser { 'pybal-check':
        name          => 'pybal-check',
        home          => '/var/lib/pybal-check',
        shell         => '/bin/sh',
        default_group => 'pybal-check',
    }

    file { '/var/lib/pybal-check/.ssh':
        ensure  => directory,
        owner   => 'pybal-check',
        group   => 'pybal-check',
        mode    => '0550',
    }

    file { '/var/lib/pybal-check/.ssh/authorized_keys':
        owner   => 'pybal-check',
        group   => 'pybal-check',
        mode    => '0440',
        source  => 'puppet:///modules/mediawiki/pybal_key',
    }
}
