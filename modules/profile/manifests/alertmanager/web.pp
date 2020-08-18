# enable_sso is a temporary workaround for the fact that:
# * the alerting_host role is shared with icinga
# * profile::idp::client::httpd_legacy is already used by icinga
# * profile::idp::client::httpd_legacy is a class, so we can't reuse for alerts.w.o
# Thus ship a httpd::site with the mod_auth_cas parameters expanded as needed

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

    acme_chief::cert { 'alerts':
        puppet_svc => 'apache2',
    }

    httpd::site { $vhost:
        content => template('profile/alertmanager/web.apache.erb'),
        require => Class['Profile::Idp::Client::Httpd_legacy'],
    }

    $hosts = join($prometheus_nodes, ' ')
    ferm::service { 'alertmanager-web':
        proto  => 'tcp',
        port   => 19194,
        srange => "@resolve((${hosts}))",
    }
}
