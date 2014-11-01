class openstack::queue-server($openstack_version, $novaconfig) {
    if ! defined(Class['openstack::repo']) {
        class { 'openstack::repo': openstack_version => $openstack_version }
    }

    package { [ 'rabbitmq-server' ]:
        ensure  => present,
        require => Class['openstack::repo'];
    }
}
