class role::ml_k8s::worker {
    include profile::base::production
    include profile::firewall

    # Setup dfdaemon (needs to be included before the container runtime)
    include profile::dragonfly::dfdaemon
    if $::hostname == 'ml-serve2001' {
      # Sets up containerd on the machine
      include profile::kubernetes::container_runtime
    } else {
      # Sets up docker on the machine
      include profile::docker::engine
    }
    # Setup kubernetes stuff
    include profile::kubernetes::node
    # Setup calico
    include profile::calico::kubernetes
    # Support for AMD GPUs
    include profile::amd_gpu

    # Setup LVS
    include profile::lvs::realserver
}
