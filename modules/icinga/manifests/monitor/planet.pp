# T203208
class icinga::monitor::planet(
    Stdlib::Httpsurl $url,
    Integer $warn,
    Integer $crit,
){

    @monitoring::host { 'planet':
        host_fqdn => 'en.planet.wikimedia.org',
    }

    @monitoring::service { 'Planet_content_updates':
        description   => 'check updates on en.planet.wikimedia.org',
        check_command => "check_lastmod!${url}!${warn}!${crit}",
        host          => 'planet',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Planet.wikimedia.org',
    }
}
