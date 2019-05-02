class role::wmcs::openstack::codfw1dev::puppetmaster::frontend {
    system::role { $name: }
    include ::profile::standard
    include ::profile::openstack::codfw1dev::clientpackages
    include ::profile::openstack::codfw1dev::observerenv
    include ::profile::openstack::codfw1dev::puppetmaster::frontend
    include ::profile::openstack::base::optional_firewall
}
