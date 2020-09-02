# enable_sso is used to disable sso in cloud

class profile::alertmanager::web (
    # lint:ignore:wmf_styleguide - T260574
    String $vhost  = lookup('profile::alertmanager::web::vhost', {'default_value' => "alerts.${facts['domain']}"}),
    # lint:endignore
    Boolean $enable_sso  = lookup('profile::alertmanager::web::enable_sso', {'default_value' => true}),
    Boolean $readonly  = lookup('profile::alertmanager::web::readonly', {'default_value' => true}),
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes'),
) {
    $auth_header = $enable_sso ? {
        true  => 'X-CAS-uid',
        false => undef,
    }

    class { 'alertmanager::karma':
        vhost          => $vhost,
        listen_address => '0.0.0.0',
        listen_port    => 19194,
        auth_header    => $auth_header,
    }

    if $enable_sso {
        profile::idp::client::httpd::site { $vhost:
            document_root   => '/var/www/html',
            acme_chief_cert => 'icinga',
            vhost_content   => 'profile/idp/client/httpd-karma.erb',
            vhost_settings  => { 'readonly' => $readonly },
            required_groups => [
                'cn=ops,ou=groups,dc=wikimedia,dc=org',
                'cn=wmf,ou=groups,dc=wikimedia,dc=org',
                'cn=nda,ou=groups,dc=wikimedia,dc=org',
            ],
        }
    } else {
        httpd::site { $vhost:
            content => template('profile/alertmanager/web.apache.erb'),
        }
    }

    $hosts = join($prometheus_nodes, ' ')
    ferm::service { 'alertmanager-web':
        proto  => 'tcp',
        port   => 19194,
        srange => "@resolve((${hosts}))",
    }
}
