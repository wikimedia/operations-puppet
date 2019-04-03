class role::wmcs::openstack::eqiad1::services_secondary {
    system::role { $name: }
    include ::standard
    include ::profile::base::firewall
    include ::profile::openstack::eqiad1::pdns::auth::db
    include ::profile::openstack::eqiad1::pdns::auth::service
    include ::profile::openstack::eqiad1::pdns::recursor::secondary
    include ::profile::openstack::eqiad1::designate::service
    include ::profile::ldap::client::labs
}
