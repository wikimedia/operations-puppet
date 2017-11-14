# == Class: bird::base
#
# Installs Bird
# Let the option to "bindTo" the Bird service to another service (watchdog-like)
#
#
class bird(
  $neighbors,
  $bfd = true,
  $bind_service = '',
  $routerid= $::ipaddress,
  ){

  require_package('bird')

  if $bind_service != '' {
    exec { 'bird-systemd-reload':
        command     => 'systemctl daemon-reload',
        path        => [ '/usr/bin', '/bin', '/usr/sbin' ],
        refreshonly => true,
    }
    file { '/lib/systemd/system/bird.service':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('bird/bird.service.erb'),
        require => Package['bird'],
        notify  => Exec['bird-systemd-reload'],
    }
  }

  service { 'bird':
      ensure  => running,
      enable  => true,
      restart => 'service bird reload',
      require => Package['bird'],
  }

  service { 'bird6':
      ensure  => stopped,
      enable  => false,
      restart => 'service bird6 reload',
      require => Package['bird'],
  }

  file { '/etc/bird/bird.conf':
      ensure  => present,
      owner   => 'bird',
      group   => 'bird',
      mode    => '0640',
      content => template('bird/bird_anycast.conf.erb'),
      notify  => Service['bird'],
  }

}
