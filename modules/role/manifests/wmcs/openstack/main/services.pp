class role::wmcs::openstack::main::services {
    include ::profile::openstack::main::cloudrepo
    include ::profile::openstack::main::designate::service
}
