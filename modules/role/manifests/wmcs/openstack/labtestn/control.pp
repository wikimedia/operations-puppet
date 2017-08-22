class role::wmcs::openstack::labtestn::control {
    include ::profile::openstack::labtestn::observerenv
    include ::profile::openstack::labtestn::rabbitmq
    include ::profile::openstack::labtestn::keystone::service
    include ::profile::openstack::labtestn::glance
}
