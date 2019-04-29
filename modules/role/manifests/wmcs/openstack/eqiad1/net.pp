class role::wmcs::openstack::eqiad1::net {
    system::role { $name: }
    # Do not add base firewall
    include ::profile::standard
    include ::profile::openstack::eqiad1::clientpackages
    include ::profile::openstack::eqiad1::observerenv
    include ::profile::openstack::eqiad1::neutron::common
    # TODO: partial config?
    include ::profile::openstack::eqiad1::neutron::l3_agent
    include ::profile::openstack::eqiad1::neutron::dhcp_agent
    # TODO: needs appropriate pinning for jessie mitaka
    include ::profile::openstack::eqiad1::neutron::metadata_agent
    include ::profile::wmcs::services::oidentd::proxy
}
