class role::wmcs::openstack::main::control {
    include ::profile::openstack::main::observerenv
    include ::profile::openstack::main::rabbitmq
    include ::profile::openstack::main::keystone::service
    include ::profile::openstack::main::glance
    include ::profile::openstack::main::nova::common
    include ::profile::openstack::main::nova::conductor::service
    include ::profile::openstack::main::nova::scheduler::service
    include ::profile::openstack::main::salt
}
