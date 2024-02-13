# monitor en.planet.wikimedia.org certificate
# and check it's being updated regularly
# T203208, T203208
# warn / crit: time in hours before content is considered stale
class icinga::monitor::planet(
    Stdlib::Httpsurl $url,
    Integer $warn,
    Integer $crit,
){

    @monitoring::host { 'en.planet.wikimedia.org':
        host_fqdn     => 'en.planet.wikimedia.org',
    }

    monitoring::service { 'https_planet':
        description   => 'HTTPS-planet',
        check_command => 'check_ssl_http_letsencrypt!en.planet.wikimedia.org',
        host          => 'en.planet.wikimedia.org',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Planet.wikimedia.org',
    }
}
