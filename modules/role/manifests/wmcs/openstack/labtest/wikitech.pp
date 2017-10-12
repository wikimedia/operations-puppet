class role::wmcs::openstack::labtest::wikitech {
    system::role { $name: }
    include ::profile::openstack::labtest::cloudrepo
    include ::profile::openstack::labtest::clientlib
}
