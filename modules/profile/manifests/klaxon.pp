class profile::klaxon (
    Klaxon::Klaxon_config $config   = lookup('profile::klaxon::klaxon_config', {'merge' => hash}),
    String $escalation_policy_slug  = lookup('profile::klaxon::escalation_policy_slug'),
) {
    $port = 4667

    class {'klaxon':
        escalation_policy_slug => $escalation_policy_slug,
        port                   => $port,
        config                 => $config,
    }

    $ssl_settings = ssl_ciphersuite('apache', 'strong', true)

    profile::idp::client::httpd::site {'klaxon.wikimedia.org':
        require         => [
            Acme_chief::Cert['icinga'],
        ],
        vhost_content   => 'profile/idp/client/httpd-klaxon.erb',
        # These four groups are the best current proxy for "trusted contributors".
        required_groups => [
            'cn=nda,ou=groups,dc=wikimedia,dc=org',
            'cn=ops,ou=groups,dc=wikimedia,dc=org',
            'cn=wmf,ou=groups,dc=wikimedia,dc=org',
            'cn=wmde,ou=groups,dc=wikimedia,dc=org',
        ],
        # This is the common prefix of all login-required handlers in Klaxon.
        protected_uri   => '/protected/',
        vhost_settings  => { port => $port },
    }
}
