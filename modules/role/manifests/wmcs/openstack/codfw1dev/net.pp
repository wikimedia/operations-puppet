class role::wmcs::openstack::codfw1dev::net {
    system::role { $name: }
    # Do not add base firewall
    include ::standard
    include ::profile::openstack::codfw1dev::clientpackages
    include ::profile::openstack::codfw1dev::observerenv
    include ::profile::openstack::codfw1dev::neutron::common
    include ::profile::openstack::codfw1dev::neutron::l3_agent
    include ::profile::openstack::codfw1dev::neutron::dhcp_agent
    include ::profile::openstack::codfw1dev::neutron::metadata_agent
}
