# sets up rabbitmq on the nova controller
class openstack::queue-server {

    include openstack::repo

    package { [ 'rabbitmq-server' ]:
        ensure  => present,
        require => Class['openstack::repo'];
    }

    if $::fqdn == hiera('labs_nova_controller') {
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
