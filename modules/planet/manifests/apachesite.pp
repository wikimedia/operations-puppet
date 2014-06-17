# defined type: an apache site config for a planet-venus language version
define planet::apachesite {

    $sites_directory = '/etc/apache2/sites-enabled'

    file { "${sites_directory}/${title}.planet.${planet::planet_domain_name}":
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('planet/apache/planet-language.erb'),
        require => Class['planet::webserver'],
    }

}
