class openstack::api-service($openstack_version="folsom", $novaconfig) {
    if ! defined(Class["openstack::repo"]) {
        class { "openstack::repo": openstack_version => $openstack_version }
    }

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
