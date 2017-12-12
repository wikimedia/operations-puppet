# sets up the planet-venus index/portal site
class planet::index_site (
    $domain_name,
    $meta_link,
){

    httpd::site { "planet.${domain_name}":
        content => template('planet/apache/planet.erb'),
    }

}
