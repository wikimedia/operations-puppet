class openstack::neutron::service::pike(
    Stdlib::Port $bind_port,
    Boolean $active,
    ) {
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::pike::${::lsbdistcodename}"

    package { 'neutron-server':
        ensure => 'present',
    }

    service {'neutron-server':
        ensure    => $active,
        require   => Package['neutron-server'],
        subscribe => [
                      File['/etc/neutron/neutron.conf'],
                      File['/etc/neutron/policy.yaml'],
                      File['/etc/neutron/plugins/ml2/ml2_conf.ini'],
            ],
    }
}
