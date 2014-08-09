# sets up the planet-venus index/portal site
class planet::index_site {

    $ssl_settings = ssl_ciphersuite('apache-2.2', 'compat')

    apache::site { "planet.${planet::planet_domain_name}":
        content => template('planet/apache/planet.erb'),
    }

}
