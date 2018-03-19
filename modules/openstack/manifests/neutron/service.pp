class openstack::neutron::service(
    $version,
    ) {

    package {'neutron-server':
        ensure => 'present',
    }

    service {'neutron-server':
        ensure    => 'running',
        require   => Package['neutron-server'],
        subscribe => [
                      File['/etc/neutron/neutron.conf'],
                      File['/etc/neutron/policy.json'],
                      File['/etc/neutron/plugins/ml2/ml2_conf.ini'],
            ],
    }
}
