# wikimetrics.pp - role class defining the wikimetrics website

# == Class role::wikimetrics
# Wikimetrics is the mediawiki metric reporting website
class role::wikimetrics {
    # This is not a real class checked in to any repository.
    # In labs on your self hosted puppetmaster, you must do two
    # things to make this exist:
    # 1. Edit /var/lib/git/operations/puppet/manifests/passwords.pp
    #    and add this class with the variables below.
    # 2. Edit /var/lib/git/operations/puppet/manifests/site.pp
    #    and add an 'import "passwords.pp" line near the top.
    include passwords::wikimetrics

    $flask_secret_key      = $::passwords::wikimetrics::flask_secret_key
    $google_client_secret  = $::passwords::wikimetrics::google_client_secret
    $google_client_id      = $::passwords::wikimetrics::google_client_id
    $google_client_email   = $::passwords::wikimetrics::google_client_email

    # MediaWiki OAuth Creds
    $meta_mw_consumer_key  = $::passwords::wikimetrics::meta_mw_consumer_key
    $meta_mw_client_secret = $::passwords::wikimetrics::meta_mw_client_secret

    # Wikimetrics Database Creds
    $db_user_wikimetrics   = $::passwords::wikimetrics::db_user_wikimetrics
    $db_pass_wikimetrics   = $::passwords::wikimetrics::db_pass_wikimetrics
    $db_host_wikimetrics   = $::passwords::wikimetrics::db_host_wikimetrics
    $db_name_wikimetrics   = $::passwords::wikimetrics::db_name_wikimetrics
    # LabsD Database Creds
    $db_user_labsdb        = $::passwords::wikimetrics::db_user_labsdb
    $db_pass_labsdb        = $::passwords::wikimetrics::db_pass_labsdb


    # wikimetrics does not yet run via puppet in production
    if $::realm == 'labs' {
        # move this out of this conditional when possible to install in production.
        class { '::wikimetrics': }
        class { '::wikimetrics::database':
            db_name => $db_name_wikimetrics,
            db_user => $db_user_wikimetrics,
            db_pass => $db_pass_wikimetrics,
            db_host => $db_host_wikimetrics,
        }

        # if the global variable $::wikimetrics_server_name is set,
        # use it as the server_name.  This allows
        # configuration via the Labs Instance configuration page.
        $server_name = $::wikimetrics_server_name ? {
            undef   => [$::fqdn],
            default => $::wikimetrics_server_name,
        }
        $server_aliases = $::wikimetrics_server_aliases ? {
            undef   => [],
            default => split($::wikimetrics_server_aliases, ','),
        }

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