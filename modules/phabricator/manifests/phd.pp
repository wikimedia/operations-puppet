# == Class: phabricator::phd
#
# Setup PHD service to run securely
#

class phabricator::phd (
    $settings = {},
    $basedir  = '/',
) {
    group { 'phd':
        ensure => present,
        system => true,
    }

    # PHD user needs perms to drop root perms on start
    file { "${basedir}/phabricator/scripts/daemon/":
        owner   => $settings['phd.user'],
        recurse => true,
    }

    # Managing repo's as the PHD user
    file { "${basedir}/phabricator/scripts/repository/":
        owner   => $settings['phd.user'],
        recurse => true,
    }

    file { '/var/run/phd':
        ensure => directory,
        owner  => 'phd',
        group  => 'phd',
    }

    file { $settings['phd.pid-directory']:
        ensure => 'directory',
        owner  => 'phd',
        group  => 'phd',
    }

    file { $settings['phd.log-directory']:
        ensure => 'directory',
        owner  => 'phd',
        group  => 'phd',
    }

    user { $settings['phd.user']:
        gid    => 'phd',
        shell  => '/bin/false',
        home   => '/var/run/phd',
        system => true,
    }

    logrotate::conf { 'phd':
        ensure => present,
        source => 'puppet:///modules/phabricator/logrotate_phd',
    }
}
