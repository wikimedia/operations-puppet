# SPDX-License-Identifier: Apache-2.0
class role::kubernetes::staging::worker {
    include profile::base::production
    include profile::firewall

    # Setup dfdaemon
    include profile::dragonfly::dfdaemon
    # Sets up the container runtime used by kubernetes
    include profile::kubernetes::container_runtime
    # Setup kubernetes stuff
    include profile::kubernetes::node
    # Setup calico
    include profile::calico::kubernetes
    # Setup LVS
    include profile::lvs::realserver
}
