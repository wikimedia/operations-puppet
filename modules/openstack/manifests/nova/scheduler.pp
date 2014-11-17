class openstack::nova::scheduler($novaconfig) {
    include openstack::repo

    package { "nova-scheduler":
        ensure  => present,
        require => Class["openstack::repo"];
    }

    service { "nova-scheduler":
        ensure    => running,
        subscribe => File['/etc/nova/nova.conf'],
        require   => Package["nova-scheduler"];
    }
}

