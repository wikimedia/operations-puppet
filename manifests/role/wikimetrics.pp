# wikimetrics.pp - role class defining the wikimetrics website

# == Class role::wikimetrics
# Wikimetrics is the mediawiki metric reporting website
class role::wikimetrics {
    include passwords::wikimetrics

    # TODO: Fill these in from private(?)
    $flask_secret_key     = $::passwords::wikimetrics::flask_secret_key
    $google_client_secret = $::passwords::wikimetrics::google_client_secret
    $google_client_id     = $::passwords::wikimetrics::google_client_id
    $google_client_email  = $::passwords::wikimetrics::google_client_email

    # Wikimetrics Database Creds
    $db_user_wikimetrics = $::passwords::wikimetrics::db_user_wikimetrics
    $db_pass_wikimetrics = $::passwords::wikimetrics::db_pass_wikimetrics
    $db_host_wikimetrics = $::passwords::wikimetrics::db_host_wikimetrics
    $db_name_wikimetrics = $::passwords::wikimetrics::db_name_wikimetrics
    # Mediawiki Database Creds
    $db_user_mediawiki   = $::passwords::wikimetrics::db_user_mediawiki
    $db_pass_mediawiki   = $::passwords::wikimetrics::db_pass_mediawiki

    # wikimetrics does not yet run via puppet in production
    if $::realm == 'labs' {
        # move this out of this conditional when possible to install in production.
        class { '::wikimetrics': }

        $server_name          = 'metrics.wmflabs.org'
        $server_aliases       = ['metrics.instance-proxy.wmflabs.org', 'wikimetrics.pmtpa.wmflabs']

    }
    else {
        $server_name = 'metrics.wikimedia.org'
        $server_aliases = []
        fail('Cannot include role::wikimetrics in production.')
    }
}

class role::wikimetrics::queue inherits role::wikimetrics {
    class { '::wikimetrics::queue':
        db_user_wikimetrics => $db_user_wikimetrics,
        db_pass_wikimetrics => $db_pass_wikimetrics,
        db_host_wikimetrics => $db_host_wikimetrics,
        db_name_wikimetrics => $db_name_wikimetrics,
        db_user_labsdb      => $db_user_labsdb,
        db_pass_labsdb      => $db_pass_labsdb
    }
}

class role::wikimetrics::web inherits role::wikimetrics {
    class { '::wikimetrics::web':
        server_name          => $server_name,
        server_aliases       => $server_aliases,
        flask_secret_key     => $flask_secret_key,
        google_client_id     => $google_client_id,
        google_client_email  => $google_client_email,
        google_client_secret => $google_client_secret,
    }
}