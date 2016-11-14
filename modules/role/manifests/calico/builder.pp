class role::calico::builder {
    include  standard
    include profile::docker::storage::loopback
    inlcude profile::docker::engine
    include profile::calico::builder
}
