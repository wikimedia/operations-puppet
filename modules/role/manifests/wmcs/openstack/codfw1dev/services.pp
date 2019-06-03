class role::wmcs::openstack::codfw1dev::services {
    system::role { $name: }
    include ::profile::standard
    include ::profile::base::firewall
    if os_version('debian >= stretch') {
        include ::profile::openstack::base::pdns3hack
    }
    include ::profile::openstack::codfw1dev::pdns::auth::db
    include ::profile::openstack::codfw1dev::pdns::auth::service
    include ::profile::openstack::codfw1dev::pdns::recursor::service
    include ::profile::openstack::codfw1dev::designate::service
    include ::profile::prometheus::pdns_exporter
    include ::profile::prometheus::pdns_rec_exporter
    include ::profile::openldap
}
