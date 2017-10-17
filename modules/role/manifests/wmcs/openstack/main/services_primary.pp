class role::wmcs::openstack::main::services_primary {
    system::role { $name: }
    include ::profile::openstack::main::cloudrepo
    include ::profile::openstack::main::pdns::auth::db
    include ::profile::openstack::main::pdns::auth::service
    include ::profile::openstack::main::pdns::recursor::primary
    include ::profile::openstack::main::designate::service
    include ::profile::openstack::main::pdns::dns_floating_ip_updater
}
