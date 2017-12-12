# defined type: an apache site config for a planet-venus language version
define planet::apachesite (
    $domain_name = $domain_name,
) {

    if $title == 'en' {
        $priority = 10
    } else {
        $priority = 50
    }

    httpd::site { "${title}.planet.${domain_name}":
        content  => template('planet/apache/planet-language.erb'),
        priority => $priority,
    }

}
