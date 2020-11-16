# Provision an apache virtualhost to reverse-proxy AM API access

class profile::alertmanager::api (
    # lint:ignore:wmf_styleguide - T260574
    String $vhost  = lookup('profile::alertmanager::api::vhost', {'default_value' => "alertmanager.${facts['domain']}"}),
    # lint:endignore
    Array[Stdlib::Host] $ro_hosts = lookup('profile::alertmanager::api::ro'),
    Array[Stdlib::Host] $rw_hosts = lookup('profile::alertmanager::api::rw'),
) {
    httpd::site { $vhost:
        content => template('profile/alertmanager/api.apache.erb'),
    }
}
