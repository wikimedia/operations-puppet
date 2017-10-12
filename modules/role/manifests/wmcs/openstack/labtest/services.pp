class role::wmcs::openstack::labtest::services {
    system::role { $name: }
    include ::profile::openstack::labtest::cloudrepo
    include ::profile::openstack::labtest::pdns::auth::db
    include ::profile::openstack::labtest::pdns::auth::service
    include ::profile::openstack::labtest::pdns::recursor::service
    include ::profile::openstack::labtest::designate::service
}
