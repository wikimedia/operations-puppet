class role::wmcs::openstack::labtest::services {
    include ::profile::openstack::labtest::cloudrepo
    include ::profile::openstack::labtest::pdns::auth::db
    include ::profile::openstack::labtest::pdns::auth::service
    include ::profile::openstack::labtest::designate::service

}
