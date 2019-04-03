class role::wmcs::openstack::main::net {
    system::role { $name: }
    include ::standard
    include ::profile::openstack::main::clientpackages
    include ::profile::openstack::main::observerenv
    include ::profile::openstack::main::nova::common
    include ::profile::openstack::main::nova::network::service
    include ::profile::openstack::main::nova::api::service
    include ::profile::openstack::main::nova::fullstack::service
}
