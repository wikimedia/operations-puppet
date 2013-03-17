# type: index html and css theme for a planet-venus language

define planet::theme {

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
