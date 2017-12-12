# defined type: an apache site config for a planet-venus language version
define planet::apachesite {

    if $title == 'en' {
        $priority = '10'
    } else {
        $priority = '50'
    }

    apache::site { "${title}.planet.${planet::domain_name}":
        content  => template('planet/apache/planet-language.erb'),
        priority => $priority,
    }

}
