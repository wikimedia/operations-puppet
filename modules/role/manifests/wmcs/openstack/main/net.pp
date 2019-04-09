class role::wmcs::openstack::main::net {
    system::role { $name: }
    include ::standard
    include ::profile::openstack::eqiad1::clientpackages
    include ::profile::openstack::eqiad1::observerenv
    include ::profile::openstack::main::nova::common
    include ::profile::openstack::main::nova::network::service
    include ::profile::openstack::main::nova::api::service
}
