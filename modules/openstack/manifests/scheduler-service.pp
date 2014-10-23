class openstack::scheduler-service($openstack_version="folsom", $novaconfig) {
    if ! defined(Class["openstack::repo"]) {
        class { "openstack::repo": openstack_version => $openstack_version }
    }

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

