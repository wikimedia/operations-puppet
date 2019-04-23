class role::wmcs::openstack::main::services_primary {
    system::role { $name: }
    include ::standard
    include ::profile::base::firewall
    include ::profile::openstack::main::pdns::auth::db
    include ::profile::openstack::main::pdns::auth::service
    include ::profile::openstack::main::pdns::recursor::primary
    #include ::profile::openstack::main::designate::service
    #include ::profile::prometheus::pdns_exporter
    #include ::profile::prometheus::pdns_rec_exporter_wmcs
    include ::profile::ldap::client::labs
}
