class role::wmcs::openstack::main::control {
    system::role { $name: }
    include ::standard
    include ::profile::base::firewall
    include ::profile::openstack::main::observerenv
    include ::profile::openstack::main::rabbitmq
    include ::profile::openstack::main::keystone::service
    include ::profile::openstack::main::envscripts
    include ::profile::openstack::main::nova::common
    include ::profile::openstack::main::nova::conductor::service
    include ::profile::openstack::main::nova::scheduler::service
    include ::profile::ldap::client::labs
    include ::profile::openstack::main::pdns::dns_floating_ip_updater
}
