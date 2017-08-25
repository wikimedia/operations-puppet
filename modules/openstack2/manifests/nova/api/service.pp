# This is the api service for Openstack Nova.
# It provides a REST api that  Wikitech and Horizon use to manage VMs.
class openstack2::nova::api::service(
    $active,
    ) {

    require openstack2::nova::common

    package { 'nova-api':
        ensure  => present,
    }

    # Temp exclude
    #    subscribe => [
    #                  File['/etc/nova/nova.conf'],
    #                  File['/etc/nova/policy.json'],
    #        ],
    service { 'nova-api':
        ensure  => $active,
        require => Package['nova-api'];
    }
}
