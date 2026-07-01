class role::ml_k8s::master {
    include profile::base::production
    include profile::firewall

    # Sets up kubernetes on the machine
    include profile::kubernetes::master

    # Needed to schedule containers like bird, used by calico.
    # Sets up containerd on the machine
    include profile::kubernetes::container_runtime
    include profile::kubernetes::node
    include profile::calico::kubernetes

    # LVS configuration (VIP)
    include profile::lvs::realserver

    # IPIP for LVS (T420438)
    include profile::lvs::realserver::ipip
}
