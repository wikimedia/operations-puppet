# SPDX-License-Identifier: Apache-2.0
class role::dse_k8s::master {
    include profile::base::production
    include profile::firewall

    # Sets up kubernetes on the machine
    include profile::kubernetes::master

    # Sets up containerd on the machine
    include profile::kubernetes::container_runtime
    # Setup kubernetes stuff
    include profile::kubernetes::node
    # Setup calico
    include profile::calico::kubernetes

    # LVS configuration (VIP)
    include profile::lvs::realserver
    include profile::lvs::realserver::ipip
}
