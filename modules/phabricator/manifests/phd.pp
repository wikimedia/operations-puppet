# == Class: phabricator::phd
#
# Setup PHD service to run securely
#

class phabricator::phd (
    $settings = {},
    $basedir  = '/',
) {
    $run_dir = $settings['phd.run-directory']

    file { '/etc/init.d/phd':
        ensure => 'link',
        target => "${basedir}/phabricator/bin/phd",
    }

    file { $run_dir:
        ensure => 'directory',
        owner  => $settings['phd.user'],
        group  => 'phd',
    }

    file { "${run_dir}/pid":
        ensure  => 'directory',
        owner   => $settings['phd.user'],
        group   => 'phd',
        require => File[$run_dir],
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
