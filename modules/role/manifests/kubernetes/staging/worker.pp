class role::kubernetes::staging::worker {
    include ::profile::standard
    include ::profile::base::firewall

    # Sets up docker on the machine
    include ::profile::docker::storage
    include ::profile::docker::engine
    include ::profile::kubernetes::node
    include ::profile::calico::kubernetes
}
