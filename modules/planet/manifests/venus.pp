# http://planet.wikimedia.org/ - new planet (planet-venus)
# http://intertwingly.net/code/venus/

class planet::venus( $planet_domain_name, $planet_languages ) {

  $planet_languages_keys = keys($planet_languages)

  include planet::packages,
          planet::locales,
          planet::dirs

  systemuser { 'planet':
    name   => 'planet',
    home   => '/var/lib/planet',
    groups => [ 'planet' ],
  }

  File {
    owner => 'planet',
    group => 'planet',
    mode  => '0644',
  }

  file {
    '/etc/apache2/ports.conf':
      ensure => present,
      mode   => '0444',
      owner  => 'root',
      group  => 'root',
      source => 'puppet:///modules/planet/ssl/ports.conf.ssl';
    "/etc/apache2/sites-available/planet.${planet_domain_name}":
      mode    => '0444',
      owner   => 'root',
      group   => 'root',
      content => template('planet/apache/planet.erb');
    '/usr/share/planet-venus/theme/common/images/planet-wm2.png':
      source => 'puppet:///modules/planet/theme/images/planet-wm2.png';
  }

  planet::config { $planet_languages_keys: }

  planet::docroot { $planet_languages_keys: }

  planet::cronjob { $planet_languages_keys: }

  planet::theme { $planet_languages_keys: }

  # Apache site without language, redirects to meta
  apache_site {
    'planet':
      name => "planet.${planet_domain_name}"
  }

  # the actual *.planet language versions
  planet::apache_site{ $planet_languages_keys: }

}
