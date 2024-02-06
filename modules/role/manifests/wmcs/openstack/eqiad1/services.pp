class role::wmcs::openstack::eqiad1::services {
    system::role { $name: }
    include ::profile::base::production
    include ::profile::firewall
    include profile::base::cloud_production
    include profile::wmcs::cloud_private_subnet
    include profile::wmcs::cloud_private_subnet::bgp
    include ::profile::openstack::eqiad1::pdns::auth::db
    include ::profile::openstack::eqiad1::pdns::auth::service
    include ::profile::openstack::eqiad1::pdns::recursor::service
    include ::profile::openstack::eqiad1::observerenv
    include ::profile::openstack::eqiad1::envscripts
    include ::profile::ldap::client::utils
    include ::profile::dbbackups::mydumper
    include ::profile::backup::host
}
