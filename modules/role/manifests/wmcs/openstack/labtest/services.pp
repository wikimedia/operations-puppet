class role::wmcs::openstack::labtest::services {
    system::role { $name: }
    include ::standard
    include ::profile::base::firewall
    include ::profile::openstack::labtest::cloudrepo
    include ::profile::openstack::labtest::pdns::auth::db
    include ::profile::openstack::labtest::pdns::auth::service
    include ::profile::openstack::labtest::pdns::recursor::service
    include ::profile::openstack::labtest::designate::service
    include ::profile::openstack::labtest::pdns::dns_floating_ip_updater
}
