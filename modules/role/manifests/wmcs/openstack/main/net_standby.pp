class role::wmcs::openstack::main::net_standby {
    system::role { $name: }
    include ::standard
    include ::profile::openstack::main::cloudrepo
    include ::profile::openstack::main::clientlib
    include ::profile::openstack::main::observerenv
    include ::profile::openstack::main::nova::common
    include ::profile::openstack::main::nova::api::service
}
