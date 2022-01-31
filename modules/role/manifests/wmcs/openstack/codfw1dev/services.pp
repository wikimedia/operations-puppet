class role::wmcs::openstack::codfw1dev::services {
    system::role { $name: }
    include ::profile::base::production
    include ::profile::base::firewall
    include ::profile::openstack::codfw1dev::pdns::auth::db
    include ::profile::openstack::codfw1dev::pdns::auth::service
    include ::profile::openstack::codfw1dev::pdns::recursor::service
    include ::profile::openstack::codfw1dev::designate::service

    if debian::codename::le('buster') {
        include ::profile::prometheus::pdns_exporter
        include ::profile::prometheus::pdns_rec_exporter
    }

    # For testing purposes, these boxes host a non-production ldap cluster
    #  with test accounts/groups/etc.  eqiad1 services boxes do not
    #  host ldap; it's just crammed on here because it's convenient.
    include ::profile::openldap_clouddev
}
