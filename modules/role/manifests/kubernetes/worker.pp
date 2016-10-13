class role::kubernetes::worker {
    # Sets up docker on the machine
    include ::profile::docker::engine
}
