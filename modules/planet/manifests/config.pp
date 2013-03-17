# type: config dir and file for a planet-venus language
define planet::config {

  file {
    "/usr/share/planet-venus/wikimedia/${title}":
      ensure => directory;
      path   => "/usr/share/planet-venus/wikimedia/${title}",
      mode   => '0755',
      owner  => 'planet',
      group  => 'planet',
    "/usr/share/planet-venus/wikimedia/${title}/config.ini":
      path    => "/usr/share/planet-venus/wikimedia/${title}/config.ini",
      ensure  => present,
      owner   => 'planet',
      group   => 'planet',
      mode    => '0444',
      content => template('planet/feeds/${title}_config.erb'),
    }
}
