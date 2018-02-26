class profile::openstack::labtestn::neutron::service {
    require ::profile::openstack::labtestn::clientlib
    class {'::profile::openstack::base::neutron::service':}
    contain '::profile::openstack::base::neutron::service'
}
