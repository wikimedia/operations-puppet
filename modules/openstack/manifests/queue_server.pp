# sets up rabbitmq on the nova controller
class openstack::queue_server {

    include openstack::repo

    package { [ 'rabbitmq-server' ]:
        ensure  => present,
        require => Class['openstack::repo'];
    }

    # Turn up the number of allowed file handles for rabbitmq
    file { '/etc/default/rabbitmq-env.conf':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/openstack/rabbitmq/labs-rabbitmq.default',
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
