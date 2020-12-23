# This is the api service for Openstack Nova.
# It provides a REST api that  Wikitech and Horizon use to manage VMs.
class openstack::nova::api::service(
    $version,
    $active,
    Stdlib::Port $api_bind_port,
    ) {

    class { "openstack::nova::api::service::${version}":
        api_bind_port => $api_bind_port,
    }

    service { 'nova-api':
        ensure    => $active,
        subscribe => [
                      File['/etc/nova/nova.conf'],
                      File['/etc/nova/policy.yaml'],
            ],
        require   => Package['nova-api'];
    }
}
