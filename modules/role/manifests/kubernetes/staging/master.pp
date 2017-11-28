class role::kubernetes::staging::master {
    include ::standard
    include ::base::firewall

    # Sets up docker on the machine
    include ::profile::kubernetes::master
}
