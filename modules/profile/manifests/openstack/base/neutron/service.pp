class profile::openstack::base::neutron::service {
    class {'::openstack::neutron::service':}
    contain '::openstack::neutron::service'
}
