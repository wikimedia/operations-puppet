# SPDX-License-Identifier: Apache-2.0
class role::aux_k8s::worker {
    system::role { 'role::aux_k8s::worker ':
        description => 'aux kubernetes worker node',
    }

    # setup standard profiles
    include profile::base::production
    include profile::base::firewall

    # setup docker on the machine
    include profile::docker::engine
    # setup as a kubernetes node
    include profile::kubernetes::node
    # setup calico, our kubernetes CNI
    include profile::calico::kubernetes

    # LVS configuration, for service VIPs
    # include ::profile::lvs::realserver
}
