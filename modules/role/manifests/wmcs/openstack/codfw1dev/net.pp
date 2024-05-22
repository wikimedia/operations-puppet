class role::wmcs::openstack::codfw1dev::net {
  include profile::base::production
  include profile::base::no_firewall
  include profile::base::cloud_production
  include profile::wmcs::cloud_private_subnet

  include profile::openstack::codfw1dev::observerenv
  include profile::openstack::codfw1dev::neutron::common

  include profile::openstack::codfw1dev::neutron::l3_agent
  include profile::openstack::codfw1dev::neutron::dhcp_agent
  include profile::openstack::codfw1dev::neutron::metadata_agent
}
