class role::wmcs::openstack::main::wikitech {
    system::role { $name: }
    include ::profile::openstack::main::cloudrepo
    include ::profile::openstack::main::clientlib
}
