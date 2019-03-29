class openstack::neutron::service(
    $version,
    ) {

    class { "openstack::neutron::service::${version}": }

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
