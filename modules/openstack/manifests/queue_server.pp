# sets up rabbitmq on the nova controller
class openstack::queue_server(
        $rabbit_username,
        $rabbit_password
    ) {

    include openstack::repo

    package { [ 'rabbitmq-server' ]:
        ensure  => present,
        require => Class['openstack::repo'];
    }

    # Turn up the number of allowed file handles for rabbitmq
    file { '/etc/default/rabbitmq-server':
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

    diamond::collector { 'rabbitmq':
        settings => {
            'host'     => 'localhost:15672',
            'user'     => $rabbit_username,
            'password' => $rabbit_password,
        },
        source   => 'puppet:///modules/openstack/rabbitmq/rabbitmq.py',
    }
}
