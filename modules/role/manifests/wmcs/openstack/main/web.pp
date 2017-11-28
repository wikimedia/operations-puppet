class role::wmcs::openstack::main::web {
    system::role { $name: }
    include ::profile::openstack::main::cloudrepo
    include ::profile::openstack::main::clientlib
    include ::profile::openstack::main::observerenv
}
