# international locales for a planet-venus install
class planet::locales {

  # locales are important for planet
  # they can be auto-updated though
  package { 'locales':
    ensure => latest;
  }

  #FIXME - move into module
  file { '/var/lib/locales/supported.d/local':
    source => 'puppet:///files/locales/local_int',
    owner  => 'root',
    group  => 'root',
    mode   => '0444';
  }

  # generate locales
  exec { '/usr/sbin/locale-gen':
    subscribe   => File['/var/lib/locales/supported.d/local'],
    refreshonly => true,
    require     => File['/var/lib/locales/supported.d/local'];
  }

}
