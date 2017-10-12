class role::wmcs::openstack::main::services_secondary {
    system::role { $name: }
    include ::profile::openstack::main::cloudrepo
    include ::profile::openstack::main::pdns::auth::db
    include ::profile::openstack::main::pdns::auth::service
    include ::profile::openstack::main::designate::service
}
