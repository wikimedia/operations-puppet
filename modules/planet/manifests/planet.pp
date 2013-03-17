# http://planet.wikimedia.org/ - new planet (planet-venus)
# http://intertwingly.net/code/venus/

class misc::planet-venus( $planet_domain_name, $planet_languages ) {

  $planet_languages_keys = keys($planet_languages)

  package { 'planet-venus':
    ensure => latest;
  }

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

  file { [
    '/var/www/planet',
    '/var/log/planet',
    '/usr/share/planet-venus/wikimedia',
    '/usr/share/planet-venus/theme/wikimedia',
    '/usr/share/planet-venus/theme/common',
    '/var/cache/planet'
    ]:
    ensure => 'directory',
    mode => '0755',
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

  define planetconfig {

    file {
      "/usr/share/planet-venus/wikimedia/${title}":
        ensure => directory,
        path   => "/usr/share/planet-venus/wikimedia/${title}",
        mode   => '0755',
        owner  => 'planet',
        group  => 'planet';
      "/usr/share/planet-venus/wikimedia/${title}/config.ini":
        path    => "/usr/share/planet-venus/wikimedia/${title}/config.ini",
        ensure  => present,
        owner   => 'planet',
        group   => 'planet',
        mode    => '0444',
        content => template('planet/feeds/${title}_config.erb');
    }
  }

  planetconfig { $planet_languages_keys: }

  define planetwwwdir {

    file {
      "/var/www/planet/${title}":
        ensure => directory,
        path   => "/var/www/planet/${title}",
        owner  => 'planet',
        group  => 'www-data',
        mode   => '0755',
    }
  }

  planetwwwdir { $planet_languages_keys: }

  define planetcronjob {

    cron {
      "update-${title}-planet":
      ensure  => present,
      command => "/usr/bin/planet -v /usr/share/planet-venus/wikimedia/${title}/config.ini > /var/log/planet/${title}-planet.log 2>&1",
      user    => 'planet',
      minute  => '0',
      require => [User['planet']];
    }

  }

  planetcronjob { $planet_languages_keys: }

  define planettheme {

    file {
      "/usr/share/planet-venus/theme/wikimedia/${title}":
        ensure => directory;
      "/usr/share/planet-venus/theme/wikimedia/${title}/index.html.tmpl":
        ensure  => present,
        content => template('planet/html/index.html.tmpl.erb');
      "/usr/share/planet-venus/theme/wikimedia/${title}/config.ini":
        source => 'puppet:///modules/planet/theme/config.ini';
      "/usr/share/planet-venus/theme/wikimedia/${title}/planet.css":
        source    => $title ? {
          'ar'    => 'puppet:///modules/planet/theme/planet-ar.css',
          default => 'puppet:///modules/planet/theme/planet.css',
          },

    }


  }

  planettheme { $planet_languages_keys: }

  define planetapachesite {

    file {
      "/etc/apache2/sites-available/${title}.planet.${planet_domain_name}":
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('planet/apache/planet-language.erb');
    }

    apache_site {
      "${title}-planet":
        name => "${title}.planet.${planet_domain_name}"
    }

  }

  # Apache site without language, redirects to meta
  apache_site {
    'planet':
      name => "planet.${planet_domain_name}"
  }

  # the actual *.planet language versions
  planetapachesite{ $planet_languages_keys: }

}
