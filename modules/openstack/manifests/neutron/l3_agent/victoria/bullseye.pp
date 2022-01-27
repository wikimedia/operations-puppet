class openstack::neutron::l3_agent::victoria::bullseye(
) {
    require openstack::serverpackages::victoria::bullseye

    package { 'neutron-l3-agent':
        ensure => 'present',
    }
}
