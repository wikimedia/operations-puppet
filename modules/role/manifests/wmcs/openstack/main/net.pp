class role::wmcs::openstack::main::net {
    include profile::openstack::main::cloudrepo
    include ::profile::openstack::main::clientlib
    include ::profile::openstack::main::observerenv
    include ::profile::openstack::main::nova::common
    include ::profile::openstack::main::nova::network::service
    include ::profile::openstack::main::nova::api::service
    include ::profile::openstack::main::nova::fullstack::service
}
