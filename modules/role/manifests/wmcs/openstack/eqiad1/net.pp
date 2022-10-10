class role::wmcs::openstack::eqiad1::net {
    system::role { $name: }
    # Do not add base firewall
    include profile::base::production
    include profile::openstack::eqiad1::clientpackages
    include profile::openstack::eqiad1::observerenv
    include profile::openstack::eqiad1::neutron::common
    include profile::openstack::eqiad1::neutron::l3_agent
    include profile::openstack::eqiad1::neutron::dhcp_agent
    include profile::openstack::eqiad1::neutron::metadata_agent
    include profile::wmcs::services::oidentd::proxy
}
