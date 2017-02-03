# filtertags: labs-project-packaging
class role::calico::builder {
    include  standard
    include profile::docker::storage::loopback
    include profile::docker::engine
    include profile::calico::builder
}
