class role::kubernetes::staging::worker {
    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::base::firewall::log

    # Sets up docker on the machine
    include ::profile::docker::storage
    include ::profile::docker::engine
    include ::profile::kubernetes::node
    include ::profile::calico::kubernetes
}
