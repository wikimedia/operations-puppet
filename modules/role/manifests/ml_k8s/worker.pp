class role::ml_k8s::worker {
    include ::profile::standard
    include ::profile::base::firewall

    # Sets up docker on the machine
    include ::profile::docker::storage
    include ::profile::docker::engine
    # Setup kubernetes stuff
    include ::profile::kubernetes::node
    # Setup calico
    include ::profile::calico::kubernetes
    # Setup LVS
    # Leabe LVS unconfigured during POC phase
    #include ::profile::lvs::realserver

    system::role { 'kubernetes::worker':
        description => 'ML Kubernetes worker node',
    }
}
