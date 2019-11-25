# This is the placement-api service for Openstack Nova.
class openstack::nova::placement::service(
    String $version,
    String $active,
    ) {

    class { "openstack::nova::placement::service::${version}": }

    service { 'nova-placement':
        ensure    => $active,
        subscribe => [
                      File['/etc/nova/nova.conf'],
                      File['/etc/nova/policy.json'],
            ],
        require   => Package['nova-placement-api'];
    }
}
