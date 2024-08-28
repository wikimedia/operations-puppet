class role::wmcs::openstack::codfw1dev::control {
    include profile::base::production
    include profile::firewall
    include profile::base::cloud_production
    include profile::wmcs::cloud_private_subnet

    include profile::openstack::codfw1dev::metrics
    include profile::openstack::codfw1dev::observerenv
    include profile::openstack::codfw1dev::rabbitmq

    include profile::openstack::codfw1dev::keystone::apache
    include profile::openstack::codfw1dev::keystone::service
    include profile::openstack::codfw1dev::keystone::fernet_keys
    include profile::openstack::codfw1dev::envscripts
    include profile::openstack::codfw1dev::keystone::bootstrap
    include profile::openstack::codfw1dev::glance
    include profile::openstack::codfw1dev::placement
    include profile::openstack::codfw1dev::cinder
    include profile::openstack::codfw1dev::cinder::volume
    include profile::openstack::codfw1dev::trove
    include profile::openstack::codfw1dev::designate::service
    include profile::openstack::codfw1dev::radosgw
    include profile::openstack::codfw1dev::rbd_cloudcontrol
    include profile::openstack::codfw1dev::networktests

    # For testing purposes:
    include profile::openstack::codfw1dev::barbican
    include profile::openstack::codfw1dev::heat
    include profile::openstack::codfw1dev::magnum

    include profile::openstack::codfw1dev::nova::common
    include profile::openstack::codfw1dev::nova::conductor::service
    include profile::openstack::codfw1dev::nova::scheduler::service
    include profile::openstack::codfw1dev::nova::api::service
    include profile::openstack::codfw1dev::neutron::common
    include profile::openstack::codfw1dev::neutron::service

    include profile::ldap::client::utils
    include profile::memcached::instance
    # include profile::openstack::codfw1dev::neutron::metadata_agent
    include profile::openstack::codfw1dev::designate::dns_floating_ip_updater
    include profile::openstack::codfw1dev::opentofu

    include profile::openstack::codfw1dev::galera::node
    include profile::openstack::codfw1dev::galera::backup

    include profile::openstack::codfw1dev::nova::fullstack::service

    include profile::cloudceph::auth::deploy
}
