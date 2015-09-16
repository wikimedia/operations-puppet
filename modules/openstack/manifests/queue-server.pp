class openstack::queue-server(
    $novaconfig
) {
    include openstack::repo

    package { [ 'rabbitmq-server' ]:
        ensure  => present,
        require => Class['openstack::repo'];
    }

    if $::hostname == hiera('labs_nova_controller') {
        service { 'rabbitmq-server':
            ensure    => running,
            require   => Package['rabbitmq-server'];
        }
    } else {
        service { 'rabbitmq-server':
            ensure    => stopped,
            require   => Package['rabbitmq-server'];
        }
    }
}
