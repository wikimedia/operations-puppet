class role::ml_k8s::master {
    include ::profile::standard
    include ::profile::base::firewall

    # Sets up kubernetes on the machine
    include ::profile::kubernetes::master
    # Strictly speaking kubectl isn't needed, but have it here for historical
    # reasons
    include ::profile::kubernetes::client

    # LVS configuration (VIP)
    include ::profile::lvs::realserver

    system::role { 'kubernetes::master':
        description => 'ML Kubernetes master server',
    }
}
