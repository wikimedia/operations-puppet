# SPDX-License-Identifier: Apache-2.0
class role::dse_k8s::worker {
    include profile::base::production
    include profile::firewall

    # Setup dfdaemon (needs to be included before the container runtime)
    include profile::dragonfly::dfdaemon
    # Sets up containerd on the machine
    include profile::kubernetes::container_runtime
    # Setup kubernetes stuff
    include profile::kubernetes::node
    # dse-k8s-specific tweaks (ref T402926)
    include profile::kubernetes::node::dse_k8s
    # Setup calico
    include profile::calico::kubernetes
    # Support for AMD GPUs
    include profile::amd_gpu
    # Install the Maxmind GeoIP databases for analytics work
    include profile::analytics::geoip

    # Setup LVS
    include profile::lvs::realserver
    include profile::lvs::realserver::ipip
}
