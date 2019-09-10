class role::wmcs::openstack::eqiad1::cumin_controller {
    system::role { $name: }
    include ::profile::standard
    include ::profile::openstack::eqiad1::clientpackages
    include ::profile::openstack::eqiad1::observerenv
    include ::profile::openstack::base::optional_firewall
    include ::profile::openstack::eqiad1::cumin::master
}
