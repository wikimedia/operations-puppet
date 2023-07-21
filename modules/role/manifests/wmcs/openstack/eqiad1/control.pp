class role::wmcs::openstack::eqiad1::control {
    system::role { $name: }
    include profile::base::production
    include profile::firewall
    include profile::base::cloud_production

    if $facts['hostname'] != 'cloudcontrol1005' {
        # the only server on the new network setup
        include profile::wmcs::cloud_private_subnet
    }

    include profile::openstack::eqiad1::metrics
    include profile::openstack::eqiad1::observerenv

    include profile::openstack::eqiad1::keystone::service
    include profile::openstack::eqiad1::keystone::fernet_keys
    include profile::openstack::eqiad1::envscripts
    include profile::openstack::eqiad1::neutron::common
    include profile::openstack::eqiad1::neutron::service
    include profile::openstack::eqiad1::glance
    include profile::openstack::eqiad1::placement
    include profile::openstack::eqiad1::cinder
    include profile::openstack::eqiad1::cinder::volume
    include profile::openstack::eqiad1::trove
    include profile::openstack::eqiad1::heat
    include profile::openstack::eqiad1::magnum
    include profile::cloudceph::client::rbd_glance
    include profile::openstack::eqiad1::nova::common
    include profile::openstack::eqiad1::nova::conductor::service
    include profile::openstack::eqiad1::nova::scheduler::service
    include profile::openstack::eqiad1::nova::api::service

    if $facts['hostname'] != 'cloudcontrol1005' {
        # the only server on the new network setup
        include profile::openstack::eqiad1::haproxy
        include profile::prometheus::haproxy_exporter
    }

    include profile::ldap::client::utils
    include profile::openstack::eqiad1::pdns::dns_floating_ip_updater
    include profile::openstack::eqiad1::nova::fullstack::service
    include profile::memcached::instance
    include profile::openstack::eqiad1::nova::instance_purge
    include profile::openstack::eqiad1::galera::node
    include profile::openstack::eqiad1::galera::monitoring
    include profile::openstack::eqiad1::galera::backup
    include profile::toolforge::mark_tool
    include profile::openstack::eqiad1::networktests
    include profile::cloudceph::auth::deploy
    include profile::wmcs::services::maintain_dbusers
    include profile::wmcs::services::ldap_disable_tool
}
