# As above, but for misc instead of generic prod
class role::cache::ssl_misc {
    #TODO: kill the old wmf_ca
    include certificates::wmf_ca
    include certificates::wmf_ca_2014_2017
    include role::protoproxy::ssl::common

    role::cache::localssl { 'wikimedia.org':
        certname       => 'sni.wikimedia.org',
        server_name    => 'wikimedia.org',
        server_aliases => ['*.wikimedia.org'],
        default_server => true;
    }

    role::cache::localssl { 'wmfusercontent.org':
        certname       => 'star.wmfusercontent.org',
        server_name    => 'wmfusercontent.org',
        server_aliases => ['*.wmfusercontent.org'];
    }

    role::cache::localssl { 'planet.wikimedia.org':
        certname       => 'star.planet.wikimedia.org',
        server_name    => 'planet.wikimedia.org',
        server_aliases => ['*.planet.wikimedia.org'];
    }
}
