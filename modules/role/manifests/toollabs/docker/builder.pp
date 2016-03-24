class role::toollabs::docker::builder {
    include ::toollabs::infrastructure

    require role::labs::lvm::srv
    class { '::docker::engine': }

    class { '::docker::baseimages': }
}
