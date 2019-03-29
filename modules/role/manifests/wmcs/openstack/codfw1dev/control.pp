class role::wmcs::openstack::codfw1dev::control {
    system::role { $name: }
    include ::standard
    include ::profile::base::firewall
    include ::profile::openstack::codfw1dev::clientpackages
    include ::profile::openstack::codfw1dev::observerenv
    include ::profile::openstack::codfw1dev::rabbitmq
    include ::profile::openstack::codfw1dev::keystone::service
    include ::profile::openstack::codfw1dev::envscripts
    include ::profile::openstack::codfw1dev::keystone::bootstrap
    include ::profile::openstack::codfw1dev::glance
    include ::profile::openstack::codfw1dev::nova::common
    include ::profile::openstack::codfw1dev::nova::conductor::service
    include ::profile::openstack::codfw1dev::nova::scheduler::service
    include ::profile::openstack::codfw1dev::nova::api::service
    include ::profile::openstack::codfw1dev::neutron::common
    include ::profile::openstack::codfw1dev::neutron::service
    # include ::profile::openstack::codfw1dev::neutron::metadata_agent
    # include ::profile::openstack::codfw1dev::nova::spiceproxy::service
    # include ::profile::openstack::codfw1dev::pdns::dns_floating_ip_updater
}
