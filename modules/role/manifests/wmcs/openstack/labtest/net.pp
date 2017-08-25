class role::wmcs::openstack::labtest::net {
    include profile::openstack::labtest::cloudrepo
    include ::profile::openstack::labtestn::nova::common
    include ::profile::openstack::labtestn::nova::network::service
    include ::profile::openstack::labtestn::nova::api::service
}
