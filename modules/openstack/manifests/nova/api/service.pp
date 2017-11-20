# This is the api service for Openstack Nova.
# It provides a REST api that  Wikitech and Horizon use to manage VMs.
class openstack::nova::api::service(
    $active,
    ) {

    require openstack::nova::common

    package { 'nova-api':
        ensure  => present,
    }

    service { 'nova-api':
        ensure    => $active,
        subscribe => [
                      File['/etc/nova/nova.conf'],
                      File['/etc/nova/policy.json'],
            ],
        require   => Package['nova-api'];
    }
}
