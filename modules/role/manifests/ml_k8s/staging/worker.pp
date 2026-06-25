class role::ml_k8s::staging::worker {
    include profile::base::production
    include profile::firewall

    # Setup dfdaemon (needs to be included before the container runtime)
    include profile::dragonfly::dfdaemon
    # Sets up containerd on the machine
    include profile::kubernetes::container_runtime
    # Setup kubernetes stuff
    include profile::kubernetes::node
    # Setup calico
    include profile::calico::kubernetes
    # Support for AMD GPUs
    include profile::amd_gpu

    # Setup LVS
    include profile::lvs::realserver

    # IPIP tunneling (see
    # https://wikitech.wikimedia.org/wiki/Kubernetes/Clusters/IPIP and T420438)
    include profile::lvs::realserver::ipip
}
