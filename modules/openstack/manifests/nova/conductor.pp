class openstack::nova::conductor($novaconfig) {
    include openstack::repo

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
