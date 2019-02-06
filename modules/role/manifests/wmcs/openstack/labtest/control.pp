class role::wmcs::openstack::labtest::control {
    system::role { $name: }
    include ::standard
    include ::profile::base::firewall
    include ::profile::openstack::labtest::observerenv
    include ::profile::openstack::labtest::rabbitmq
    include ::profile::openstack::labtest::keystone::service
    include ::profile::openstack::labtest::envscripts
    include ::profile::openstack::labtest::glance
    include ::profile::openstack::labtest::nova::common
    include ::profile::openstack::labtest::nova::conductor::service
    include ::profile::openstack::labtest::nova::scheduler::service
    include ::profile::openstack::labtest::pdns::dns_floating_ip_updater
}
