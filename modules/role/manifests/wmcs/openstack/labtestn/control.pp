class role::wmcs::openstack::labtestn::control {
    system::role { $name: }
    include ::standard
    include ::profile::base::firewall
    include ::profile::openstack::labtestn::clientlib
    include ::profile::openstack::labtestn::observerenv
    #include ::profile::openstack::labtestn::rabbitmq
    #include ::profile::openstack::labtestn::keystone::service
    #include ::profile::openstack::labtestn::keystone::bootstrap
    #include ::profile::openstack::labtestn::glance
    #include ::profile::openstack::labtestn::nova::common
    #include ::profile::openstack::labtestn::nova::conductor::service
    #include ::profile::openstack::labtestn::nova::scheduler::service
    #include ::profile::openstack::labtestn::nova::api::service
    #include ::profile::openstack::labtestn::nova::spiceproxy::service
    #include ::profile::openstack::labtestn::neutron::service
}
