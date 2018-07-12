class profile::openstack::base::neutron::l3_agent(
    $version = hiera('profile::openstack::base::version'),
    $dmz_cidr = hiera('profile::openstack::base::neutron::dmz_cidr'),
    $network_public_ip = hiera('profile::openstack::base::neutron::network_public_ip'),
    $report_interval = hiera('profile::openstack::base::neutron::report_interval'),
    ) {

    class {'::openstack::neutron::l3_agent':
        version           => $version,
        dmz_cidr          => $dmz_cidr,
        network_public_ip => $network_public_ip,
        report_interval   => $report_interval,
    }
    contain '::openstack::neutron::l3_agent'
}
