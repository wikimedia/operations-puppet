class role::wmcs::openstack::labtest::net {
    system::role { $name: }
    include ::standard
    include ::profile::openstack::labtest::cloudrepo
    include ::profile::openstack::labtest::nova::common
    include ::profile::openstack::labtest::nova::network::service
    include ::profile::openstack::labtest::nova::api::service
}
