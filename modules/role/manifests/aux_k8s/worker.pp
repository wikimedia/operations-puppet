# SPDX-License-Identifier: Apache-2.0
class role::aux_k8s::worker {
    # setup standard profiles
    include profile::base::production
    include profile::firewall

    include profile::kubernetes::container_runtime
    # setup as a kubernetes node
    include profile::kubernetes::node
    # setup calico, our kubernetes CNI
    include profile::calico::kubernetes

    # LVS configuration, for service VIPs
    include profile::lvs::realserver
    include profile::lvs::realserver::ipip
}
