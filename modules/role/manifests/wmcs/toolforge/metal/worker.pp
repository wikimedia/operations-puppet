# SPDX-License-Identifier: Apache-2.0

# Based on role::kubernetes::worker
class role::wmcs::toolforge::metal::worker {
    include profile::base::production
    include profile::firewall

    # dfdaemon needs to be included before container runtime
    include profile::dragonfly::dfdaemon
    include profile::kubernetes::container_runtime
    include profile::kubernetes::node

    include profile::calico::kubernetes

    include profile::lvs::realserver
}
