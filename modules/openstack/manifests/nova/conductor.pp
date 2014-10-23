class openstack::nova::conductor($openstack_version="folsom", $novaconfig) {
    if ! defined(Class["openstack::repo"]) {
        class { "openstack::repo": openstack_version => $openstack_version }
    }

    package { "nova-conductor":
        ensure  => present,
        require => Class["openstack::repo"];
    }

    service { "nova-conductor":
        ensure    => running,
        subscribe => File['/etc/nova/nova.conf'],
        require   => Package["nova-conductor"];
    }
}
