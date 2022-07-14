# SPDX-License-Identifier: Apache-2.0
# Role to configure an etcd v3 cluster for use with the dse_k8s cluster.

class role::etcd::v3::dse_k8s_etcd {
    include ::profile::base::production
    include ::profile::base::firewall
    #include ::profile::etcd::v3

    system::role { 'role::etcd::v3::dse_k8s_etcd':
        description => 'dse_k8s_etcd etcd cluster member'
    }
}
