class role::kubernetes::staging::master {
    include ::standard
    include ::profile::base::firewall

    # Sets up docker on the machine
    include ::profile::kubernetes::master
}
