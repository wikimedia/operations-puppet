# type: apache site config for a planet-venus language version

define planet::apache_site {

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
