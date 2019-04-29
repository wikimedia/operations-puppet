class role::kubernetes::master {
    include ::profile::standard
    include ::profile::base::firewall

    # Sets up docker on the machine
    include ::profile::kubernetes::master
    if hiera('has_lvs', true) {
        # TODO: This needs to become a profile
        include role::lvs::realserver
    }
}
