class role::builder {
    include role::package::builder
    include profile::docker::storage::loopback
    include profile::docker::engine
    include profile::docker::builder
}
