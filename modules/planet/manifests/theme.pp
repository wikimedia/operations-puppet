# type: index html and css theme for a planet-venus language

define planet::theme {

  File {
    owner => 'planet',
    group => 'planet',
    mode  => '0644',
  }

  file {
    "/usr/share/planet-venus/theme/wikimedia/${title}":
      ensure => directory;
    "/usr/share/planet-venus/theme/wikimedia/${title}/index.html.tmpl":
      ensure  => present,
      content => template('planet/html/index.html.tmpl.erb');
    "/usr/share/planet-venus/theme/wikimedia/${title}/config.ini":
      source => 'puppet:///modules/planet/theme/config.ini';
    '/usr/share/planet-venus/theme/common/images/planet-wm2.png':
      source => 'puppet:///modules/planet/theme/images/planet-wm2.png';
    "/usr/share/planet-venus/theme/wikimedia/${title}/planet.css":
      source    => $title ? {
        'ar'    => 'puppet:///modules/planet/theme/planet-ar.css',
        default => 'puppet:///modules/planet/theme/planet.css',
      },
  }

}
