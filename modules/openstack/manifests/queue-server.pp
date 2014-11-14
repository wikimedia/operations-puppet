class openstack::queue-server ($novaconfig) {
    include openstack::repo

    package { [ 'rabbitmq-server' ]:
        ensure  => present,
        require => Class['openstack::repo'];
    }
}
