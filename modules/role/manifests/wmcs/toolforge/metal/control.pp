# SPDX-License-Identifier: Apache-2.0
# Based on role::kubernetes::master_stacked, i.e. co-locate etcd and control plane

class role::wmcs::toolforge::metal::control {
    include profile::base::production
    include profile::firewall

    require profile::etcd::v3

    include profile::kubernetes::master

    include profile::kubernetes::container_runtime
    include profile::kubernetes::node
    include profile::calico::kubernetes

    #include profile::lvs::realserver
}
