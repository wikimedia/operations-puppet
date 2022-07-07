class role::wmcs::openstack::eqiad1::services {
    system::role { $name: }
    include ::profile::base::production
    include ::profile::base::firewall
    include ::profile::openstack::eqiad1::pdns::auth::db
    include ::profile::openstack::eqiad1::pdns::auth::service
    include ::profile::openstack::eqiad1::pdns::recursor::service
    include ::profile::openstack::eqiad1::designate::service

    include ::profile::ldap::client::labs
}
