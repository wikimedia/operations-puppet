class role::wmcs::openstack::main::control {
    include ::profile::openstack::main::cloudrepo
    include ::profile::openstack::main::clientlib
    include ::profile::openstack::main::observerenv
    include ::profile::openstack::main::rabbitmq
    include ::profile::openstack::main::keystone::service
}
