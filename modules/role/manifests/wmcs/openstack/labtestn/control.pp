class role::wmcs::openstack::labtestn::control {
    include ::profile::openstack::labtestn::cloudrepo
    include ::profile::openstack::labtestn::clientlib
    include ::profile::openstack::labtestn::observerenv
    include ::profile::openstack::labtestn::rabbitmq
    include ::profile::openstack::labtestn::keystone::service
}
