class openstack::nova::api($openstack_version=$::openstack::version, $novaconfig) {
    include openstack::repo

    package {  [ "nova-api" ]:
        ensure  => present,
        require => Class["openstack::repo"];
    }

    service { "nova-api":
        ensure    => running,
        subscribe => File['/etc/nova/nova.conf'],
        require   => Package["nova-api"];
    }
    file { "/etc/nova/policy.json":
        source  => "puppet:///modules/openstack/${openstack_version}/nova/policy.json",
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        notify  => Service["nova-api"],
        require => Package["nova-api"];
    }
}
