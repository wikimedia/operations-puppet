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

    # phd service is only running on active server set in Hiera
    # will be changed after cluster setup is finished
    $phabricator_active_server = hiera('phabricator_active_server')
    if $::hostname == $phabricator_active_server {
        $phd_service_ensure = 'running'
    } else {
        $phd_service_ensure = 'stopped'
    }

    # This needs to become <s>Upstart</s> systemd managed
    # https://secure.phabricator.com/book/phabricator/article/managing_daemons/
    # Meanwhile upstream has a bug to make an LSB friendly wrapper
    # https://secure.phabricator.com/T8129
    # see examples of real-word unit files in comments of:
    # https://secure.phabricator.com/T4181
    base::service_unit { 'phd':
        ensure         => 'present',
        systemd        => true,
        sysvinit       => true,
        strict         => false,
        service_params => {
            ensure     => $phd_service_ensure,
            enable     => true,
            hasrestart => true,
            status     => '/usr/bin/pgrep -f phd-daemon',
            start      => '/usr/sbin/service phd start --force',
        },
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
