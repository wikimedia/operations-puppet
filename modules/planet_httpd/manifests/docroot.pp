# defined type: a document root for a planet-venus language
define planet_httpd::docroot {

    file { "/var/www/planet/${title}":
        ensure => 'directory',
        path   => "/var/www/planet/${title}",
        owner  => 'planet',
        group  => 'www-data',
        mode   => '0755',
    }

}
