class role::wmcs::openstack::main::net {
    include profile::openstack::main::cloudrepo
    # for keystone checks which should move to control
    include ::profile::openstack::main::clientlib
    include profile::openstack::main::observerenv
}
