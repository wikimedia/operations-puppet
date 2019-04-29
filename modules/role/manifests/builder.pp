# filtertags: labs-project-packaging
class role::builder {
    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::package_builder
    include ::profile::docker::storage::loopback
    include ::profile::docker::engine
    include ::profile::docker::builder
    include role::systemtap::devserver

    system::role { 'builder':
        description => 'Docker images builder',
    }
}
