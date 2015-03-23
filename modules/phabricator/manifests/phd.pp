# == Class: phabricator::phd
#
# Setup PHD service to run securely
#

class phabricator::phd (
    $settings = {},
    $basedir  = '/',
) {

    file { "${basedir}/phabricator/scripts/daemon/":
        owner   => $settings['phd.user'],
        recurse => true,
    }

    file { '/etc/init.d/phd':
        ensure => 'link',
        target => "${basedir}/phabricator/bin/phd",
    }

    file { $settings['phd.pid-directory']:
        ensure => 'directory',
        owner  => $settings['phd.user'],
        group  => 'phd',
    }

    file { $settings['phd.log-directory']:
        ensure => 'directory',
        owner  => $settings['phd.user'],
        group  => 'phd',
    }

    group { 'phd':
        ensure => present,
        system => true,
    }

    user { $settings['phd.user']:
        gid        => 'phd',
        shell      => '/bin/false',
        managehome => false,
        system     => true,
    }

    file { '/etc/logrotate.d/phd':
        ensure => file,
        source => 'puppet:///modules/phabricator/logrotate_phd',
        mode   => '0644',
    }
}
