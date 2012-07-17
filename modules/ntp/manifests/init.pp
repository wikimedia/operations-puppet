# NTP base class

class ntp {
  case $::operatingsystem {
    debian, ubuntu: {
      $conf    = '/etc/ntp.conf'
      $package = 'ntp'
    }
    solaris: {
      $conf    = '/etc/inet/ntp.conf'
      $package = [ SUNWntpr, SUNWntpu ]
    }
    default: {
      fail("Module ${module_name} is not supported on ${::operatingsystem}")
    }
  }

  file { 'ntp.conf':
    mode    => '0644',
    owner   => root,
    group   => root,
    path    => $conf,
    content => template('ntp/ntp-server.erb'),
  }

  package { $package:
    ensure => latest,
  }

  service { 'ntp':
    ensure    => running,
    require   => [ File['ntp.conf'], Package[$package] ],
    subscribe => File['ntp.conf'],
  }
}
