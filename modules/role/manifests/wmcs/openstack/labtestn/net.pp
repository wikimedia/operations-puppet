class role::wmcs::openstack::labtestn::net {
    system::role { $name: }
    # Do not add base firewall
    include ::standard
    include ::profile::openstack::labtestn::clientlib
    include ::profile::openstack::labtestn::observerenv
    include ::profile::openstack::labtestn::neutron::common
    include ::profile::openstack::labtestn::neutron::l3_agent
    include ::profile::openstack::labtestn::neutron::dhcp_agent
}
