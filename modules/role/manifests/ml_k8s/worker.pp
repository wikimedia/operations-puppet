class role::ml_k8s::worker {
    include ::profile::base::production
    include ::profile::base::firewall

    # Sets up docker on the machine
    include ::profile::docker::engine
    # Setup kubernetes stuff
    include ::profile::kubernetes::node
    # Setup calico
    include ::profile::calico::kubernetes

    # Setup LVS
    include ::profile::lvs::realserver

    system::role { 'kubernetes::worker':
        description => 'ML Kubernetes worker node',
    }
}
