# SPDX-License-Identifier: Apache-2.0
# Role to configure an etcd v3 cluster for use with the aux_k8s cluster.

class role::etcd::v3::aux_k8s_etcd {
    include profile::base::production
    include profile::firewall
    include profile::etcd::v3
}
