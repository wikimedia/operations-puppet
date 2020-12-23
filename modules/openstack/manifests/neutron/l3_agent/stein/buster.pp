class openstack::neutron::l3_agent::stein::buster(
) {
    require openstack::serverpackages::stein::buster

    package { 'neutron-l3-agent':
        ensure => 'present',
    }
}
