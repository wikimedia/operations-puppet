class role::wmcs::openstack::labtestn::net {
    system::role { $name: }
    # Do not add base firewall
    include ::profile::standard
    include ::profile::openstack::labtestn::clientpackages
    include ::profile::openstack::labtestn::observerenv
    include ::profile::openstack::labtestn::neutron::common
    include ::profile::openstack::labtestn::neutron::l3_agent
    include ::profile::openstack::labtestn::neutron::dhcp_agent
    include ::profile::openstack::labtestn::neutron::metadata_agent
}
