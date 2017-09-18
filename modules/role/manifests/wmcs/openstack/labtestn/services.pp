class role::wmcs::openstack::labtestn::services {
    include ::profile::openstack::labtestn::cloudrepo
    include ::profile::openstack::labtestn::pdns::auth::db
    include ::profile::openstack::labtestn::pdns::auth::service
    include ::profile::openstack::labtestn::designate::service
}
