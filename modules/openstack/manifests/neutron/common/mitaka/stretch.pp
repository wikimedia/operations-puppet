class openstack::neutron::common::mitaka::stretch(
) {
    require openstack::serverpackages::mitaka::stretch

    # packages will be installed from openstack-mitaka-jessie component from
    # the jessie-wikimedia repo, since that has higher apt pinning by default
    package { 'neutron-common':
        ensure => 'present',
    }
}
