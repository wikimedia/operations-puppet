# defined type: an apache site config for a planet-venus language version
define planet_httpd::apachesite {

    if $title == 'en' {
        $priority = 10
    } else {
        $priority = 50
    }

    httpd::site { "${title}.planet.${planet_httpd::planet_domain_name}":
        content  => template('planet/apache/planet-language.erb'),
        priority => $priority,
    }

}
