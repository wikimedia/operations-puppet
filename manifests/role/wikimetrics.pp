# wikimetrics.pp - role class defining the wikimetrics website

# == Class role::wikimetrics
# Wikimetrics is the mediawiki metric reporting website
class role::wikimetrics {
    # wikimetrics does not yet run via puppet in production
    if $::realm == 'labs' {
        # move this out of this conditional when possible to install in production.
        class { '::wikimetrics': }

        $server_name          = 'metrics.wmflabs.org'
        $server_aliases       = ['metrics.instance-proxy.wmflabs.org', 'wikimetrics.pmtpa.wmflabs']
        # TODO: Fill these in from private(?)
        $flask_secret_key     = ''
        $google_client_secret = ''
        $google_client_id     = ''
        $google_client_email  = ''
    }
    else {
        fail('Cannot include role::wikimetrics in production.')
    }
}

class role::wikimetrics::queue inherits role::wikimetrics {
    class { '::wikimetrics::queue':
        # TODO: Fill these in from private(?)
    }
}

class role::wikimetrics::web inherits role::wikimetrics {
    $server_name = $::realm ? {
        'labs'       => 'metrics.wmflabs.org',
        'production' => 'metrics.wikimedia.org',
    }

    class { '::wikimetrics::web':
        server_name          => $server_name,
        server_aliases       => $server_aliases,
        flask_secret_key     => $flask_secret_key,
        google_client_id     => $google_client_id,
        google_client_email  => $google_client_email,
        google_client_secret => $google_client_secret,
    }
}