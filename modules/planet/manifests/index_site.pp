# sets up the planet-venus index/portal site
class planet::index_site {

    file { "/etc/apache2/sites-enabled/planet.${planet::planet_domain_name}":
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('planet/apache/planet.erb'),
        require => Class['planet::webserver'],
    }

}
