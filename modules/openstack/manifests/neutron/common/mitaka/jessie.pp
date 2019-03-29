class openstack::neutron::common::mitaka::jessie(
) {
    require openstack::serverpackages::mitaka::jessie

    # package will be installed from the openstack-mitaka-jessie component
    package { 'neutron-common':
        ensure => 'present',
    }

    file {'/etc/neutron/original':
        ensure  => 'directory',
        owner   => 'neutron',
        group   => 'neutron',
        mode    => '0755',
        recurse => true,
        source  => 'puppet:///modules/openstack/mitaka/neutron/original',
    }
}
