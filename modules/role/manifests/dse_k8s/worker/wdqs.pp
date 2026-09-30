# SPDX-License-Identifier: Apache-2.0
class role::dse_k8s::worker::wdqs {
    # This role is a variant of a standard dse-k8s worker, so include that here.
    # Its hiera adds the taints and the vg_data volume group for TopoLVM.
    include role::dse_k8s::worker
}
