# type: apache site config for a planet-venus language version

define planet::apache_site {

  $sites_directory = '/etc/apache2/sites-available'

  file {
    "${sites_directory}/${title}.planet.${planet::planet_domain_name}":
      mode    => '0444',
      owner   => 'root',
      group   => 'root',
      content => template('planet/apache/planet-language.erb');
  }

  apache_site {
    "${title}-planet":
      name => "${title}.planet.${planet::planet_domain_name}"
  }

}
