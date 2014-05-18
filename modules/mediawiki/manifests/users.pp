class mediawiki::users {
    # apache

    # The name, gid, home, and shell of the apache user are set to conform
    # with the postinst script of the wikimedia-task-appserver package, which
    # provisioned it historically. These values can and should be modernized.

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

    # mwdeploy

    group { 'mwdeploy':
        ensure => present,
        system => true,
    }

    user { 'mwdeploy':
        ensure     => present,
        shell      => '/bin/false',
        home       => '/var/lib/mwdeploy',
        system     => true,
        managehome => true,
    }


    # l10nupdate

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
        owner   => 'l10nupdate',
        group   => 'l10nupdate',
        mode    => '0400',
        source  => 'puppet:///modules/mediawiki/authorized_keys.l10nupdate',
    }

    sudo_group { 'wikidev_deploy':
        group      => 'wikidev',
        privileges => [
            'ALL = (apache,mwdeploy,l10nupdate) NOPASSWD: ALL',
            'ALL = (root) NOPASSWD: /sbin/restart twemproxy',
            'ALL = (root) NOPASSWD: /sbin/start twemproxy'
        ],
    }

    sudo_user { 'l10nupdate':
        require    => User['l10nupdate', 'mwdeploy'],
        privileges => [
            'ALL = (mwdeploy) NOPASSWD: ALL',
        ],
    }
}
