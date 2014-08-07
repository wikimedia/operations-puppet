# defined type: an apache site config for a planet-venus language version
define planet::apachesite {

    apache::site { "${title}.planet.${planet::planet_domain_name}":
        content => template('planet/apache/planet-language.erb'),
    }

}
