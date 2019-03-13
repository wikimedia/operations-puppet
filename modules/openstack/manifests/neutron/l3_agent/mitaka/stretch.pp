class openstack::neutron::l3_agent::mitaka::stretch(
) {
    require openstack::serverpackages::mitaka::stretch

    # package will be installed from openstack-mitaka-jessie component from
    # the jessie-wikimedia repo, since that has higher apt pinning by default
    package { 'neutron-l3-agent':
        ensure => 'present',
    }
}
