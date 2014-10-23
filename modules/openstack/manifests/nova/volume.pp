class openstack::nova::volume($openstack_version="folsom", $novaconfig) {
    if ! defined(Class["openstack::repo"]) {
        class { "openstack::repo": openstack_version => $openstack_version }
    }

    package { [ "nova-volume" ]:
        ensure  => absent,
        require => Class["openstack::repo"];
    }

    #service { "nova-volume":
    #   ensure    => stopped,
    #   subscribe => File['/etc/nova/nova.conf'],
    #   require   => Package["nova-volume"];
    #}
}
