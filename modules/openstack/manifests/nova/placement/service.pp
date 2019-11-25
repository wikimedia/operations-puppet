# This is the placement-api service for Openstack Nova.
class openstack::nova::placement::service(
    String $version,
    Boolean $active,
    Stdlib::Port $placement_api_port,
    ) {

    class { "openstack::nova::placement::service::${version}":
        placement_api_port => $placement_api_port,
    }

    service { 'nova-placement-api':
        ensure    => $active,
        subscribe => [
                      File['/etc/nova/nova.conf'],
                      File['/etc/init.d/nova-placement-api'],
                      File['/etc/nova/policy.json'],
            ],
        require   => Package['nova-placement-api'];
    }
}
