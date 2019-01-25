# sets up the planet index/portal site
class planet::index_site (
    Stdlib::Fqdn $domain_name,
    Stdlib::Httpsurl $meta_link,
){

    httpd::site { "planet.${domain_name}":
        content => template('planet/apache/planet.erb'),
    }

}
