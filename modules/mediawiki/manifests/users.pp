# == Class: mediawiki::users
#
# Provisions system accounts for running, deploying and updating
# MediaWiki.
#
class mediawiki::users {
    include groups::wikidev

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
        shell      => '/bin/false',
        home       => '/var/lib/mwdeploy',
        system     => true,
        managehome => true,
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
        owner   => 'l10nupdate',
        group   => 'l10nupdate',
        mode    => '0400',
        source  => 'puppet:///modules/mediawiki/authorized_keys.l10nupdate',
    }

    $deployers_group = $::realm ? {
      # Bug 65548: Older ldap accounts in labs have 'svn' as the default
      # group rather than the 'wikidev' group.
      'labs' => ['wikidev', 'svn'],
      default => 'wikidev',
    }
    sudo_group { $deployers_group:
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
}
