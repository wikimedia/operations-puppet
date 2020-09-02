# This is the api service for Openstack Nova.
# It provides a REST api that  Wikitech and Horizon use to manage VMs.
class openstack::nova::api::service(
    $version,
    $active,
    ) {

    class { "openstack::nova::api::service::${version}": }

    service { 'nova-api':
        ensure    => $active,
        subscribe => [
                      File['/etc/nova/nova.conf'],
                      File['/etc/nova/policy.yaml'],
            ],
        require   => Package['nova-api'];
    }

    # Hack in regex validation for instance names.
    #  Context can be found in T207538
    file { '/usr/lib/python3/dist-packages/nova/api/openstack/compute/servers.py':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///modules/openstack/rocky/nova/hacks/servers.py',
        require => Package['nova-api'];
    }
}
