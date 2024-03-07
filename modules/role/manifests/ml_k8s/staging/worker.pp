class role::ml_k8s::staging::worker {
    include profile::base::production
    include profile::firewall

    # Sets up docker on the machine
    include profile::docker::engine
    # Setup kubernetes stuff
    include profile::kubernetes::node
    # Setup calico
    include profile::calico::kubernetes
    # Support for AMD GPUs
    include profile::amd_gpu
    # Setup dfdaemon and configure docker to use it
    include profile::dragonfly::dfdaemon

    # Setup LVS
    include profile::lvs::realserver
}
