# == Class: phabricator::phd
#
class phabricator::phd($settings = {}) {

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
        ensure  => file,
        source  => 'puppet:///modules/phabricator/logrotate_phd',
        mode    => '0644',
    }
}
