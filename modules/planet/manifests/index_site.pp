# the planet-venus index/portal site

class planet::index_site {

  file {
    "/etc/apache2/sites-available/planet.${planet_domain_name}":
      mode    => '0444',
      owner   => 'root',
      group   => 'root',
      content => template('planet/apache/planet.erb');
  }

  # Apache site without language, redirects to meta
  apache_site {
    'planet':
      name => "planet.${planet_domain_name}"
  }

}
