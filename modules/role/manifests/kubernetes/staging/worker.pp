class role::kubernetes::staging::worker {
    include profile::base::production
    include profile::firewall

    # Sets up docker on the machine
    include profile::docker::engine
    # Setup dfdaemon and configure docker to use it
    include profile::dragonfly::dfdaemon
    # Setup kubernetes stuff
    include profile::kubernetes::node
    # Setup calico
    include profile::calico::kubernetes
    # Setup LVS
    include profile::lvs::realserver
}
