class openstack::neutron::l3_agent::wallaby::bullseye(
) {
    require openstack::serverpackages::wallaby::bullseye

    package { 'neutron-l3-agent':
        ensure => 'present',
    }
}
