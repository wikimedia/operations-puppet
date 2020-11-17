# Provision an apache virtualhost to reverse-proxy AM API access

class profile::alertmanager::api (
    # lint:ignore:wmf_styleguide - T260574
    String $vhost  = lookup('profile::alertmanager::api::vhost', {'default_value' => "alertmanager.${facts['domain']}"}),
    # lint:endignore
    Array[Stdlib::Host] $ro = lookup('profile::alertmanager::api::ro'),
    Array[Stdlib::Host] $rw = lookup('profile::alertmanager::api::rw'),
) {

    $ro_hosts = $ro.filter |$el| { $el =~ Stdlib::Host }
    $ro_ips = $ro.filter |$el|   { ! $el =~ Stdlib::Host }
    $rw_hosts = $rw.filter |$el| { $el =~ Stdlib::Host }
    $rw_ips = $rw.filter |$el|   { ! $el =~ Stdlib::Host }

    httpd::site { $vhost:
        content => template('profile/alertmanager/api.apache.erb'),
    }
}
