class role::wmcs::openstack::labtest::web {
    system::role { $name: }
    include ::standard
    include ::profile::base::firewall
    include ::profile::openstack::labtest::cloudrepo
    include ::profile::openstack::labtest::clientlib
    include ::profile::openstack::labtest::observerenv
    include ::profile::openstack::labtest::wikitech::service
    include ::profile::openstack::labtest::horizon::dashboard
}
