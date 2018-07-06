# This is the api service for Openstack Nova.
# It provides a REST api that  Wikitech and Horizon use to manage VMs.
class openstack::nova::api::service(
    $version,
    $active,
    ) {

    if os_version('debian jessie') and ($version == 'mitaka') {
        $install_options = ['-t', 'jessie-backports']
    } else {
        $install_options = ''
    }

    package { 'nova-api':
        ensure          => 'present',
        install_options => $install_options,
    }

    # TEMP HOTPATCH for T198950
    if os_version('debian jessie') and ($version == 'mitaka') {
        file { '/usr/lib/python2.7/dist-packages/nova/api/manager.py':
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            source  => 'puppet:///modules/openstack/nova/api/manager.py',
            require => Package['nova-api'],
        }
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
