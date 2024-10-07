# SPDX-License-Identifier: Apache-2.0
# A profile for setting up the kubernetes control-plane
# together with a local etcd instance using containerd as the container runtime.
class role::kubernetes::staging::master_stacked_containerd {
    include profile::base::production
    include profile::firewall

    # Sets up etcd on the machine
    # profile::kubernetes::master will behave differently with this profile required
    require profile::etcd::v3
    # Sets up kubernetes on the machine
    include profile::kubernetes::master

    # Sets up containerd for kubernetes
    include profile::containerd
    include profile::kubernetes::node
    include profile::calico::kubernetes
    # Kubernetes staging masters are LVS backend servers
    include profile::lvs::realserver
}
