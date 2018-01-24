class role::wmcs::openstack::main::wikitech {
    system::role { $name: }
    include ::standard
    include ::profile::base::firewall
    include ::profile::openstack::main::cloudrepo
    include ::profile::openstack::main::clientlib
    include ::profile::openstack::main::wikitech::service
}
