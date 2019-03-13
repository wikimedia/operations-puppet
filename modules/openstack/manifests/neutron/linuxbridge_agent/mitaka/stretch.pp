class openstack::neutron::linuxbridge_agent::mitaka::stretch(
) {
    require ::openstack::serverpackages::mitaka::stretch

    package { 'libosinfo-1.0-0':
        ensure => 'present',
    }

    # package will be installed from openstack-mitaka-jessie component from
    # the jessie-wikimedia repo, since that has higher apt pinning by default
    package { 'neutron-linuxbridge-agent':
        ensure => 'present',
    }
}
