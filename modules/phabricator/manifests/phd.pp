# == Class: phabricator::phd
#
# Setup PHD service to run securely
#

class phabricator::phd (
    $settings = {},
    $basedir  = '/',
    $base_requirements = '',
    $phabricator_active_server = '',
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

    file { '/etc/init.d/phd':
        ensure => 'link',
        target => "${basedir}/phabricator/bin/phd",
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

    if $::hostname == $phabricator_active_server {
        $phd_service_ensure = 'running'
    } else {
        $phd_service_ensure = 'stopped'
    }

    if $::initsystem == 'systemd' {
      base::service_unit { 'phd':
          ensure         => 'present',
          systemd        => true,
          upstart        => false,
          sysvinit       => false,
          strict         => false,
          require        => Package['openssh-server'],
          service_params => {
              ensure     => $phd_service_ensure,
              provider   => $::initsystem,
              hasrestart => true,
          },
      }
    } else {
      # This needs to become <s>Upstart</s> systemd managed
      # https://secure.phabricator.com/book/phabricator/article/managing_daemons/
      # Meanwhile upstream has a bug to make an LSB friendly wrapper
      # https://secure.phabricator.com/T8129
      # see examples of real-word unit files in comments of:
      # https://secure.phabricator.com/T4181
      service { 'phd':
          ensure     => $phd_service_ensure,
          start      => '/usr/sbin/service phd start --force',
          status     => '/usr/bin/pgrep -f phd-daemon',
          hasrestart => true,
          require    => $base_requirements,
      }
    }
}
