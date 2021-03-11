class role::ml_k8s::master {
    include ::profile::standard
    include ::profile::base::firewall

    # Sets up kubernetes on the machine
    include ::profile::kubernetes::master

    # LVS configuration (VIP)
    include ::profile::lvs::realserver

    system::role { 'kubernetes::master':
        description => 'ML Kubernetes master server',
    }
}
