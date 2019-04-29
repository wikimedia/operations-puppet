class role::kubernetes::worker {
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
    include ::role::lvs::realserver
}
