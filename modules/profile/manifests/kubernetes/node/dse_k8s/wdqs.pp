# SPDX-License-Identifier: Apache-2.0
# @summary
#   This profile is used to make OS-level changes on dse-k8s workers that are to be
#   used for wdqs workloads.
class profile::kubernetes::node::dse_k8s::wdqs {
    # We reference the LVM class here to create the vg_data volume group
    class { 'lvm': }

    # lvmd fails to start if its volume group does not exist yet
    Class['lvm'] -> Class['profile::kubernetes::node::lvmd']
}
