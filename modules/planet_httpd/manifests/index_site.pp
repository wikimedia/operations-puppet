# sets up the planet-venus index/portal site
class planet_httpd::index_site {

    httpd::site { "planet.${planet::planet_domain_name}":
        content => template('planet/apache/planet.erb'),
    }

}
