# SPDX-License-Identifier: Apache-2.0
# A profile for setting up the kubernetes control-plane
# together with a local etcd instance.
class role::kubernetes::master_stacked {
    include profile::base::production
    include profile::firewall

    # Sets up etcd on the machine
    # profile::kubernetes::master will behave differently with this profile required
    require profile::etcd::v3
    # Sets up kubernetes on the machine
    include profile::kubernetes::master

    include profile::docker::engine
    include profile::kubernetes::node
    include profile::calico::kubernetes
    # Kubernetes masters are LVS backend servers
    include profile::lvs::realserver

    system::role { 'kubernetes::master_stacked':
        description => 'Kubernetes master server with etcd',
    }
}
