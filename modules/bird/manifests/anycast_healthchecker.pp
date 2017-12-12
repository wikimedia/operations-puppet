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

  require_package('python-anycast-healthchecker')

  file { '/etc/anycast-healthchecker.conf':
      ensure => present,
      owner  => 'bird',
      group  => 'bird',
      mode   => '0664',
      source => 'puppet:///modules/bird/anycast-healthchecker.conf',
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
      ensure  => present,
      content => template('bird/anycast-healthchecker.service.erb'),
      require => [File['/etc/anycast-healthchecker.conf'],
                  File['/var/run/anycast-healthchecker/'],
                  File['/var/log/anycast-healthchecker/'],
                  File['/etc/anycast-healthchecker.d/'], ],
  }

  service { 'anycast-healthchecker':
      ensure  => running,
      enable  => true,
      require => [Package['python-anycast-healthchecker'],
                  Systemd::Service['anycast-healthchecker'] ],
  }

}
