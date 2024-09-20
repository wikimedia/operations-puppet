# SPDX-License-Identifier: Apache-2.0
class role::kubernetes::staging::worker_containerd {
    include profile::base::production
    include profile::firewall

    # Setup dfdaemon
    include profile::dragonfly::dfdaemon
    # Sets up containerd for kubernetes
    # It will configure containerd to use the dfdaemon as the registry proxy if dfdaemon is included earlier
    include profile::containerd
    # Setup kubernetes stuff
    include profile::kubernetes::node
    # Setup calico
    include profile::calico::kubernetes
    # Setup LVS
    include profile::lvs::realserver
}
