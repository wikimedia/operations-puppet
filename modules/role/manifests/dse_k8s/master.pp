# SPDX-License-Identifier: Apache-2.0
class role::dse_k8s::master {
    include profile::base::production
    include profile::base::firewall

    # Sets up kubernetes on the machine
    #include profile::kubernetes::master
    # Strictly speaking kubectl isn't needed, but have it here for historical
    # reasons
    #include profile::kubernetes::client

    # Sets up docker on the machine
    #include ::profile::docker::engine
    # Setup kubernetes stuff
    #include ::profile::kubernetes::node
    # Setup calico
    #include ::profile::calico::kubernetes

    # LVS configuration (VIP)
    #include ::profile::lvs::realserver

    system::role { 'kubernetes::master':
        description => 'DSE Kubernetes master server',
    }
}
