class profile::openstack::base::backports{
    class { '::openstack::backports':}
    contain '::openstack::backports'
}
