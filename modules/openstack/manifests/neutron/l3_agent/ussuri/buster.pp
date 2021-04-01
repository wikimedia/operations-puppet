class openstack::neutron::l3_agent::ussuri::buster(
) {
    require openstack::serverpackages::ussuri::buster

    package { 'neutron-l3-agent':
        ensure => 'present',
    }
}
