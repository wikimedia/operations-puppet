# directories for a planet-venus intall
class planet::dirs {

  file { [
    '/var/www/planet',
    '/var/log/planet',
    '/usr/share/planet-venus/wikimedia',
    '/usr/share/planet-venus/theme/wikimedia',
    '/usr/share/planet-venus/theme/common',
    '/var/cache/planet'
    ]:
    ensure => 'directory',
    owner  => 'planet',
    group  => 'planet',
    mode   => '0755',
  }

}
