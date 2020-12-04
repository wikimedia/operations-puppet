class role::wmcs::openstack::codfw1dev::control {
    system::role { $name: }
    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::openstack::codfw1dev::observerenv
    include ::profile::openstack::codfw1dev::rabbitmq
    include ::profile::openstack::codfw1dev::keystone::apache
    include ::profile::openstack::codfw1dev::keystone::service
    include ::profile::openstack::codfw1dev::keystone::fernet_keys
    include ::profile::openstack::codfw1dev::envscripts
    include ::profile::openstack::codfw1dev::keystone::bootstrap
    include ::profile::openstack::codfw1dev::glance
    include ::profile::ceph::client::rbd_glance

    # For testing purposes:
    include ::profile::openstack::codfw1dev::barbican

    # NOTE: ceph is not enabled in this role. Starting in Queens
    #       ceph-common is a dependency for the nova-common package
    include ::profile::ceph::common
    include ::profile::openstack::codfw1dev::nova::common
    include ::profile::openstack::codfw1dev::nova::conductor::service
    include ::profile::openstack::codfw1dev::nova::scheduler::service
    include ::profile::openstack::codfw1dev::nova::api::service
    include ::profile::openstack::codfw1dev::nova::placement::service
    include ::profile::openstack::codfw1dev::neutron::common
    include ::profile::openstack::codfw1dev::neutron::service
    include ::profile::openstack::codfw1dev::haproxy
    include ::profile::openstack::codfw1dev::designate::firewall::api
    include ::profile::prometheus::haproxy_exporter
    include ::profile::ldap::client::labs
    include ::profile::memcached::instance
    # include ::profile::openstack::codfw1dev::neutron::metadata_agent
    # include ::profile::openstack::codfw1dev::pdns::dns_floating_ip_updater

    include ::profile::openstack::codfw1dev::galera::node
    include ::profile::openstack::codfw1dev::galera::monitoring
    include ::profile::openstack::codfw1dev::galera::backup
}
