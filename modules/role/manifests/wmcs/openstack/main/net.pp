class role::wmcs::openstack::main::net {
    include profile::openstack::main::cloudrepo
    # used by keystone checks which should move to control
    # and nova-fullstack which should remain on net
    include ::profile::openstack::main::clientlib
    include profile::openstack::main::observerenv
}
