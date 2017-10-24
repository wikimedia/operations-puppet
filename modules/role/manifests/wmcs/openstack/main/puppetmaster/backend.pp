class role::wmcs::openstack::main::puppetmaster::backend {
    system::role { $name: }
    include ::profile::openstack::main::clientlib
    include ::profile::openstack::main::observerenv
    include ::profile::openstack::main::puppetmaster::frontend
}
