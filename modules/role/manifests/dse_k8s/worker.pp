# SPDX-License-Identifier: Apache-2.0
class role::dse_k8s::worker {
    include profile::base::production
    include profile::firewall

    # Sets up containerd on the machine
    include profile::kubernetes::container_runtime
    # Setup kubernetes stuff
    include profile::kubernetes::node
    # Setup calico
    include profile::calico::kubernetes
    # Support for AMD GPUs
    include profile::amd_gpu

    # Setup LVS
    include profile::lvs::realserver
}
