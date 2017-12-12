# == Class: bird::anycast_healthchecker
#
# Install and configure the base of anycast_healthchecker
# https://github.com/unixsurfer/anycast_healthchecker
#
# - Global configuration file
# - pid directory
# - Services checks directory
# - Log directory
# - systemd service
#
# The actual services checks are configured with bird::anycast_healthchecker_check
#
#
class bird::anycast_healthchecker(){

  require_package('anycast-healthchecker')

  file { '/etc/anycast-healthchecker.conf':
      ensure  => present,
      owner   => 'bird',
      group   => 'bird',
      mode    => '0664',
      source  => 'puppet:///modules/bird/anycast-healthchecker.conf',
      require => Package['anycast-healthchecker'],

  }

  file {'/var/run/anycast-healthchecker/':
      ensure => directory,
      owner  => 'bird',
      group  => 'bird',
      mode   => '0775',
  }

  file {'/etc/anycast-healthchecker.d/':
      ensure => directory,
      owner  => 'bird',
      group  => 'bird',
      mode   => '0775',
  }

  file {'/var/log/anycast-healthchecker/':
      ensure => directory,
      owner  => 'bird',
      group  => 'bird',
      mode   => '0775',
  }

  systemd::service { 'anycast-healthchecker':
      content        => template('bird/anycast-healthchecker.service.erb'),
      require        => File['/etc/anycast-healthchecker.conf',
                            '/var/run/anycast-healthchecker/',
                            '/var/log/anycast-healthchecker/',
                            '/etc/anycast-healthchecker.d/',],
      restart        => true,
      service_params => {
          ensure     => 'running', # lint:ignore:ensure_first_param
      },
  }
}
