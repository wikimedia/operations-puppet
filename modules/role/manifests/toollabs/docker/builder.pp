class role::toollabs::docker::builder {
    include ::toollabs::infrastructure

    require role::labs::lvm::srv
    class { '::docker::engine': }

    class { '::docker::baseimages': }

    # Temporarily build kubernetes too! We'll eventually have this
    # be done somewhere else.
    include ::toollabs::kubebuilder
}
