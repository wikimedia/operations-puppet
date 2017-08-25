class role::wmcs::openstack::labtestn::net {
    include ::profile::openstack::labtestn::cloudrepo
    include ::profile::openstack::labtestn::nova::common
    # temporary
    include ::profile::openstack::labtestn::nova::network::service
}
