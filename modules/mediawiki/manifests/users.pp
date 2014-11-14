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

    group { 'apache':
        ensure => present,
        gid    => 48,
        system => true,
    }

    user { 'apache':
        ensure     => present,
        gid        => 48,
        shell      => '/sbin/nologin',
        home       => '/var/www',
        system     => true,
        managehome => false,
    }


    # The mwdeploy account is used by various scripts in the MediaWiki
    # deployment process to run rsync.

    group { 'mwdeploy':
        ensure => present,
        system => true,
    }

    user { 'mwdeploy':
        ensure     => present,
        shell      => '/bin/bash',
        home       => '/home/mwdeploy',
        system     => true,
        managehome => true,
    }

    file { '/home/mwdeploy':
        ensure => directory,
        owner  => 'mwdeploy',
        group  => 'mwdeploy',
        mode   => '0755',
    }

    file { '/home/mwdeploy/.ssh':
        ensure => directory,
        owner  => 'mwdeploy',
        group  => 'mwdeploy',
        mode   => '0500',
    }

    file { '/home/mwdeploy/.ssh/authorized_keys':
        source  => 'puppet:///modules/mediawiki/authorized_keys.mwdeploy',
        owner   => 'mwdeploy',
        group   => 'mwdeploy',
        mode    => '0400',
    }


    # The l10nupdate account is used for updating the localisation files
    # with new interface message translations.

    group { 'l10nupdate':
        ensure => present,
        gid    => 10002,
    }

    user { 'l10nupdate':
        ensure     => present,
        gid        => 10002,
        shell      => '/bin/bash',
        home       => '/home/l10nupdate',
        managehome => true,
    }

    file { '/home/l10nupdate/.ssh':
        ensure => directory,
        owner  => 'l10nupdate',
        group  => 'l10nupdate',
        mode   => '0500',
    }

    file { '/home/l10nupdate/.ssh/authorized_keys':
        source  => 'puppet:///modules/mediawiki/authorized_keys.l10nupdate',
        owner   => 'l10nupdate',
        group   => 'l10nupdate',
        mode    => '0400',
    }

    sudo::group { 'wikidev':
        privileges => [
            'ALL = (apache,mwdeploy,l10nupdate) NOPASSWD: ALL',
            'ALL = (root) NOPASSWD: /sbin/restart hhvm',
            'ALL = (root) NOPASSWD: /sbin/start hhvm',
            'ALL = NOPASSWD: /usr/sbin/apache2ctl',
            'ALL = NOPASSWD: /etc/init.d/apache2',
            'ALL = NOPASSWD: /usr/bin/renice',
        ],
    }

    # Grant mwdeploy sudo rights to run anything as itself or apache.
    # This allows MediaWiki deployers to deploy as mwdeploy.

    sudo::user { 'mwdeploy':
        privileges => [
            'ALL = (apache,mwdeploy,l10nupdate) NOPASSWD: ALL',
            'ALL = (root) NOPASSWD: /sbin/restart hhvm',
            'ALL = (root) NOPASSWD: /sbin/start hhvm',
        ]
    }

    sudo::user { 'l10nupdate':
        require    => User['l10nupdate', 'mwdeploy'],
        privileges => ['ALL = (mwdeploy) NOPASSWD: ALL'],
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

    file { '/var/lib/pybal-check':
        ensure  => directory,
        owner   => 'pybal-check',
        group   => 'pybal-check',
        mode    => '0755',
    }

    file { '/var/lib/pybal-check/.ssh':
        ensure  => directory,
        owner   => 'pybal-check',
        group   => 'pybal-check',
        mode    => '0550',
    }

    file { '/var/lib/pybal-check/.ssh/authorized_keys':
        source  => 'puppet:///modules/mediawiki/pybal_key',
        owner   => 'pybal-check',
        group   => 'pybal-check',
        mode    => '0440',
    }
}
