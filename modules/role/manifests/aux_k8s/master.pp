# SPDX-License-Identifier: Apache-2.0
class role::aux_k8s::master {
    # setup standard profiles
    include profile::base::production
    include profile::firewall

    # setup as a kubernetes master
    include profile::kubernetes::master
    # setup docker on the machine
    include profile::docker::engine
    # kubernete's masters are also regular nodes
    include profile::kubernetes::node
    # setup calico, our kubernetes CNI
    include profile::calico::kubernetes

    # LVS configuration, for master VIPs
    include profile::lvs::realserver
}
