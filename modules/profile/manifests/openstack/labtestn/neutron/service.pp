class profile::openstack::labtestn::neutron::service {
    require ::profile::openstack::labtestn::cloudrepo
    class {'::profile::openstack::base::neutron::service':}
    contain '::profile::openstack::base::neutron::service'
}
