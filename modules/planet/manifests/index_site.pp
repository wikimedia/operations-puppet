# sets up the planet-venus index/portal site
class planet::index_site {

    httpd::site { "planet.${planet::planet_domain_name}":
        content => template('planet/apache/planet.erb'),
    }

}
