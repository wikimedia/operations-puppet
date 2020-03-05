class openstack::neutron::service::mitaka(
    Stdlib::Port $bind_port,
    Boolean $active,
    ) {
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::mitaka::${::lsbdistcodename}"

    package { 'neutron-server':
        ensure => 'present',
    }

    service {'neutron-server':
        ensure    => $active,
        require   => Package['neutron-server'],
        subscribe => [
                      File['/etc/neutron/neutron.conf'],
                      File['/etc/neutron/policy.json'],
                      File['/etc/neutron/plugins/ml2/ml2_conf.ini'],
            ],
    }
}
