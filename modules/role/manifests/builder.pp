# filtertags: labs-project-packaging
class role::builder {
    include standard
    include ::base::firewall
    include role::package::builder
    include profile::docker::storage::loopback
    include profile::docker::engine
    include profile::docker::builder
    include role::systemtap::devserver
}
