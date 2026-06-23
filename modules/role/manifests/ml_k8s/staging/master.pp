class role::ml_k8s::staging::master {
    include profile::base::production
    include profile::firewall

    # Sets up kubernetes on the machine
    include profile::kubernetes::master

    # Needed to schedule containers like bird, used by calico.
    # More info: T285927
    # Sets up containerd on the machine
    include profile::kubernetes::container_runtime
    include profile::kubernetes::node
    include profile::calico::kubernetes

    # LVS configuration (VIP)
    include profile::lvs::realserver

    # IPIP tunneling (see
    # https://wikitech.wikimedia.org/wiki/Kubernetes/Clusters/IPIP and T420438)
    include profile::lvs::realserver::ipip
}
