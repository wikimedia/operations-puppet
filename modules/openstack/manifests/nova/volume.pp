class openstack::nova::volume($novaconfig) {
    include openstack::repo

    package { [ 'nova-volume' ]:
        ensure  => absent,
        require => Class['openstack::repo'];
    }

    #service { "nova-volume":
    #   ensure    => stopped,
    #   subscribe => File['/etc/nova/nova.conf'],
    #   require   => Package["nova-volume"];
    #}
}
