class role::kubernetes::master {
    include standard
    include ::base::firewall

    # Sets up docker on the machine
    include ::profile::kubernetes::master
}
